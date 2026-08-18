import { Injectable, NotFoundException } from '@nestjs/common';
import { AdoptionCenter } from '@prisma/client';
import { NearbyQueryDto } from '../common/dto/nearby-query.dto';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

interface RawNearbyAdoptionCenter extends AdoptionCenter {
  distanceKm: number;
}

export type AdoptionCenterResponse = AdoptionCenter & { distanceKm?: number };

@Injectable()
export class AdoptionCentersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  /** Todas las casas de adopción, con o sin ubicación cargada. */
  async findAll(): Promise<AdoptionCenterResponse[]> {
    const centers = await this.prisma.adoptionCenter.findMany({ orderBy: { name: 'asc' } });
    return centers.map((center) => this.toResponse(center));
  }

  /**
   * Casas de adopción con ubicación conocida dentro de `radiusKm` de (lat,
   * lng), ordenadas por distancia. Las que no tienen latitude/longitude
   * cargada (ver prisma/seed.ts) no pueden entrar acá — se muestran solo en
   * findAll().
   */
  async findNearby({ lat, lng, radiusKm }: NearbyQueryDto): Promise<AdoptionCenterResponse[]> {
    const radiusMeters = radiusKm * 1000;

    const rows = await this.prisma.$queryRaw<RawNearbyAdoptionCenter[]>`
      SELECT *,
        ST_Distance(
          ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
        ) / 1000 AS "distanceKm"
      FROM "adoption_centers"
      WHERE "latitude" IS NOT NULL AND "longitude" IS NOT NULL
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radiusMeters}
        )
      ORDER BY "distanceKm" ASC;
    `;

    return rows.map((row) => this.toResponse(row, row.distanceKm));
  }

  async findById(id: string): Promise<AdoptionCenterResponse> {
    const center = await this.prisma.adoptionCenter.findUnique({ where: { id } });
    if (!center) throw new NotFoundException('Casa de adopción no encontrada.');
    return this.toResponse(center);
  }

  /** `photoUrl` guarda la key del objeto en MinIO (ver prisma/seed.ts), se resuelve a URL pública acá. */
  private toResponse(center: AdoptionCenter, distanceKm?: number): AdoptionCenterResponse {
    return {
      ...center,
      photoUrl: center.photoUrl ? this.storage.resolvePhotoUrl(center.photoUrl) : null,
      ...(distanceKm !== undefined && { distanceKm }),
    };
  }
}
