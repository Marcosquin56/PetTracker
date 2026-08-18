import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { RateUserDto } from './dto/rate-user.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

export type PublicUser = Omit<
  User,
  'passwordHash' | 'refreshTokenHash' | 'lastKnownLatitude' | 'lastKnownLongitude' | 'lastKnownAddress'
> & {
  lastKnownLocation: { latitude: number; longitude: number; address: string | null } | null;
};

export interface UserSearchResult {
  id: string;
  displayName: string | null;
  photoUrl: string | null;
}

export interface PublicProfile {
  id: string;
  displayName: string | null;
  photoUrl: string | null;
  createdAt: Date;
  reportsCount: number;
  rating: { average: number | null; count: number };
}

export interface RatingListItem {
  id: string;
  score: number;
  comment: string | null;
  createdAt: Date;
  rater: { id: string; displayName: string | null; photoUrl: string | null };
}

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async findById(id: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Usuario no encontrado.');
    return this.toPublicUser(user);
  }

  async updateProfile(id: string, dto: UpdateProfileDto): Promise<PublicUser> {
    const { lastKnownLocation, ...rest } = dto;

    const user = await this.prisma.user.update({
      where: { id },
      data: {
        ...rest,
        ...(lastKnownLocation && {
          lastKnownLatitude: lastKnownLocation.latitude,
          lastKnownLongitude: lastKnownLocation.longitude,
          lastKnownAddress: lastKnownLocation.address,
        }),
      },
    });
    return this.toPublicUser(user);
  }

  /** Sube la foto de perfil a MinIO y guarda la key en `photoUrl` (mismo patrón que ReportsService.addPhoto). */
  async updatePhoto(id: string, file: Express.Multer.File): Promise<PublicUser> {
    const key = await this.storage.uploadPhoto(file, 'users');
    const user = await this.prisma.user.update({ where: { id }, data: { photoUrl: key } });
    return this.toPublicUser(user);
  }

  async addFcmToken(id: string, token: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    if (user.fcmTokens.includes(token)) return this.toPublicUser(user);

    const updated = await this.prisma.user.update({
      where: { id },
      data: { fcmTokens: { push: token } },
    });
    return this.toPublicUser(updated);
  }

  async removeFcmToken(id: string, token: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    const updated = await this.prisma.user.update({
      where: { id },
      data: { fcmTokens: user.fcmTokens.filter((existing) => existing !== token) },
    });
    return this.toPublicUser(updated);
  }

  /** Busca por displayName (nunca por email, por privacidad). Excluye al propio usuario. */
  async search(query: string, currentUserId: string): Promise<UserSearchResult[]> {
    const users = await this.prisma.user.findMany({
      where: {
        displayName: { contains: query, mode: 'insensitive' },
        id: { not: currentUserId },
      },
      select: { id: true, displayName: true, photoUrl: true },
      take: 20,
      orderBy: { displayName: 'asc' },
    });
    return users.map((user) => ({ ...user, photoUrl: this.resolveUserPhoto(user.photoUrl) }));
  }

  /** Perfil público: nombre/foto + estadísticas derivadas (reportes hechos, reputación). Nunca expone email. */
  async getPublicProfile(id: string): Promise<PublicProfile> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { id: true, displayName: true, photoUrl: true, createdAt: true },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado.');

    const [reportsCount, ratingAgg] = await Promise.all([
      this.prisma.petReport.count({ where: { reporterId: id } }),
      this.prisma.userRating.aggregate({ where: { ratedUserId: id }, _avg: { score: true }, _count: true }),
    ]);

    return {
      id: user.id,
      displayName: user.displayName,
      photoUrl: this.resolveUserPhoto(user.photoUrl),
      createdAt: user.createdAt,
      reportsCount,
      rating: { average: ratingAgg._avg.score, count: ratingAgg._count },
    };
  }

  async getRatings(id: string): Promise<RatingListItem[]> {
    const ratings = await this.prisma.userRating.findMany({
      where: { ratedUserId: id },
      orderBy: { createdAt: 'desc' },
      include: { rater: { select: { id: true, displayName: true, photoUrl: true } } },
    });
    return ratings.map((rating) => ({
      id: rating.id,
      score: rating.score,
      comment: rating.comment,
      createdAt: rating.createdAt,
      rater: { ...rating.rater, photoUrl: this.resolveUserPhoto(rating.rater.photoUrl) },
    }));
  }

  /**
   * Solo se puede calificar a alguien con quien se comparte una
   * Conversation (ver ChatService.getOrCreateConversation) — evita que
   * cualquiera califique a cualquiera sin haber interactuado. Un rating por
   * par (rater, calificado): volver a calificar pisa el anterior.
   */
  async rateUser(raterId: string, ratedUserId: string, dto: RateUserDto): Promise<void> {
    if (raterId === ratedUserId) {
      throw new BadRequestException('No podés calificarte a vos mismo.');
    }

    const sharedConversation = await this.prisma.conversation.findFirst({
      where: {
        OR: [
          { userAId: raterId, userBId: ratedUserId },
          { userAId: ratedUserId, userBId: raterId },
        ],
      },
    });
    if (!sharedConversation) {
      throw new ForbiddenException('Solo podés calificar a alguien con quien hayas tenido un chat.');
    }

    await this.prisma.userRating.upsert({
      where: { raterId_ratedUserId: { raterId, ratedUserId } },
      create: { raterId, ratedUserId, score: dto.score, comment: dto.comment },
      update: { score: dto.score, comment: dto.comment },
    });
  }

  private resolveUserPhoto(key: string | null): string | null {
    return key ? this.storage.resolvePhotoUrl(key) : null;
  }

  /**
   * Nunca devolver passwordHash/refreshTokenHash en respuestas de la API, y
   * anida lastKnownLatitude/Longitude/Address en `lastKnownLocation` para que
   * coincida con GeoLocation.fromJson() del lado Flutter.
   */
  private toPublicUser(user: User): PublicUser {
    const {
      passwordHash: _passwordHash,
      refreshTokenHash: _refreshTokenHash,
      lastKnownLatitude,
      lastKnownLongitude,
      lastKnownAddress,
      photoUrl,
      ...rest
    } = user;

    return {
      ...rest,
      photoUrl: this.resolveUserPhoto(photoUrl),
      lastKnownLocation:
        lastKnownLatitude != null && lastKnownLongitude != null
          ? { latitude: lastKnownLatitude, longitude: lastKnownLongitude, address: lastKnownAddress }
          : null,
    };
  }
}
