import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PetReport } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateReportDto } from './dto/create-report.dto';
import { NearbyQueryDto } from './dto/nearby-query.dto';
import { UpdateReportDto } from './dto/update-report.dto';

interface RawNearbyReport extends PetReport {
  distanceKm: number;
}

export type ReportResponse = Omit<PetReport, 'latitude' | 'longitude' | 'address'> & {
  location: { latitude: number; longitude: number; address: string | null };
  distanceKm?: number;
};

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly notifications: NotificationsService,
  ) {}

  async create(reporterId: string, dto: CreateReportDto): Promise<ReportResponse> {
    const report = await this.prisma.petReport.create({
      data: {
        reporterId,
        species: dto.species,
        status: dto.status,
        healthConditions: dto.healthConditions ?? [],
        photoUrls: [],
        latitude: dto.location.latitude,
        longitude: dto.location.longitude,
        address: dto.location.address,
        petName: dto.petName,
        breed: dto.breed,
        color: dto.color,
        description: dto.description,
        contactPhone: dto.contactPhone,
      },
    });

    // No bloquea la respuesta al usuario que reporta si el push falla.
    void this.notifications.notifyNearbyUsers(report);

    return this.toResponse(report);
  }

  async findById(id: string): Promise<ReportResponse> {
    return this.toResponse(await this.getRawById(id));
  }

  /** Reportes recientes sin resolver, sin filtro de ubicación (feed general). */
  async findRecent(take = 50): Promise<ReportResponse[]> {
    const reports = await this.prisma.petReport.findMany({
      where: { isResolved: false },
      orderBy: { createdAt: 'desc' },
      take,
    });
    return reports.map((report) => this.toResponse(report));
  }

  /**
   * Reportes sin resolver dentro de `radiusKm` de (lat, lng), ordenados por
   * distancia. Usa PostGIS (ST_DWithin/ST_Distance) sobre latitude/longitude
   * porque Prisma no tiene un tipo `geography` nativo — el resto del CRUD sí
   * pasa por Prisma Client normalmente.
   */
  async findNearby({ lat, lng, radiusKm }: NearbyQueryDto): Promise<ReportResponse[]> {
    const radiusMeters = radiusKm * 1000;

    const rows = await this.prisma.$queryRaw<RawNearbyReport[]>`
      SELECT *,
        ST_Distance(
          ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
        ) / 1000 AS "distanceKm"
      FROM "pet_reports"
      WHERE "isResolved" = false
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radiusMeters}
        )
      ORDER BY "distanceKm" ASC;
    `;

    return rows.map((row) => this.toResponse(row, row.distanceKm));
  }

  async update(id: string, reporterId: string, dto: UpdateReportDto): Promise<ReportResponse> {
    const report = await this.getRawById(id);
    if (report.reporterId !== reporterId) {
      throw new ForbiddenException('No puedes editar un reporte de otro usuario.');
    }

    const { location, ...rest } = dto;

    const updated = await this.prisma.petReport.update({
      where: { id },
      data: {
        ...rest,
        ...(location && {
          latitude: location.latitude,
          longitude: location.longitude,
          address: location.address,
        }),
      },
    });
    return this.toResponse(updated);
  }

  async addPhoto(id: string, reporterId: string, file: Express.Multer.File): Promise<ReportResponse> {
    const report = await this.getRawById(id);
    if (report.reporterId !== reporterId) {
      throw new ForbiddenException('No puedes editar un reporte de otro usuario.');
    }

    const key = await this.storage.uploadPhoto(file, 'reports');
    const updated = await this.prisma.petReport.update({
      where: { id },
      data: { photoUrls: { push: key } },
    });
    return this.toResponse(updated);
  }

  private async getRawById(id: string): Promise<PetReport> {
    const report = await this.prisma.petReport.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Reporte no encontrado.');
    return report;
  }

  /**
   * Anida latitude/longitude/address en `location` para calzar con
   * GeoLocation.fromJson() del lado Flutter, y resuelve `photoUrls` (keys
   * guardadas en la DB) a URLs públicas con el `S3_PUBLIC_BASE_URL` vigente.
   */
  private toResponse(report: PetReport, distanceKm?: number): ReportResponse {
    const { latitude, longitude, address, photoUrls, ...rest } = report;
    return {
      ...rest,
      photoUrls: photoUrls.map((key) => this.storage.resolvePhotoUrl(key)),
      location: { latitude, longitude, address },
      ...(distanceKm !== undefined && { distanceKm }),
    };
  }
}
