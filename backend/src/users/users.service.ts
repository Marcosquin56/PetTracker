import { Injectable, NotFoundException } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

export type PublicUser = Omit<
  User,
  'passwordHash' | 'refreshTokenHash' | 'lastKnownLatitude' | 'lastKnownLongitude' | 'lastKnownAddress'
> & {
  lastKnownLocation: { latitude: number; longitude: number; address: string | null } | null;
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

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
      ...rest
    } = user;

    return {
      ...rest,
      lastKnownLocation:
        lastKnownLatitude != null && lastKnownLongitude != null
          ? { latitude: lastKnownLatitude, longitude: lastKnownLongitude, address: lastKnownAddress }
          : null,
    };
  }
}
