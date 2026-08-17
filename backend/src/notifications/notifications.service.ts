import { Inject, Injectable, Logger } from '@nestjs/common';
import { PetReport } from '@prisma/client';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { FIREBASE_ADMIN } from './firebase-admin.provider';

interface NearbyUser {
  id: string;
  fcmTokens: string[];
}

/** Reemplaza a "Firebase Cloud Messaging desde el cliente": el push ahora lo dispara el backend. */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: admin.app.App | null,
  ) {}

  /**
   * Envía push a los usuarios con notificaciones activas cuya última
   * ubicación conocida cae dentro de SU PROPIO radio configurado respecto
   * al reporte recién creado (cada usuario define qué tan lejos le importa).
   */
  async notifyNearbyUsers(report: PetReport): Promise<void> {
    const nearbyUsers = await this.prisma.$queryRaw<NearbyUser[]>`
      SELECT "id", "fcmTokens"
      FROM "users"
      WHERE "notificationsEnabled" = true
        AND "lastKnownLatitude" IS NOT NULL
        AND "lastKnownLongitude" IS NOT NULL
        AND "id" != ${report.reporterId}
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint("lastKnownLongitude", "lastKnownLatitude"), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${report.longitude}, ${report.latitude}), 4326)::geography,
          "notificationRadiusKm" * 1000
        );
    `;

    const tokens = nearbyUsers.flatMap((user) => user.fcmTokens);
    await this.sendToTokens(tokens, {
      title: 'Nuevo reporte cerca de ti 🐾',
      body: report.petName
        ? `Vieron a ${report.petName} cerca de tu ubicación.`
        : 'Hay un nuevo reporte de mascota cerca de tu ubicación.',
      data: { type: 'report', reportId: report.id },
    });
  }

  /**
   * Push a un usuario puntual por id (a diferencia de notifyNearbyUsers, que
   * resuelve destinatarios por cercanía). Usado por el chat: cada mensaje
   * nuevo empuja al otro participante aunque no tenga el socket conectado a
   * esa conversación en ese momento.
   */
  async notifyUser(
    userId: string,
    notification: { title: string; body: string; data?: Record<string, string> },
  ): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmTokens: true, notificationsEnabled: true },
    });
    if (!user?.notificationsEnabled) return;

    await this.sendToTokens(user.fcmTokens, notification);
  }

  private async sendToTokens(
    tokens: string[],
    notification: { title: string; body: string; data?: Record<string, string> },
  ): Promise<void> {
    if (!this.firebaseApp) {
      this.logger.warn('Push deshabilitado (falta FIREBASE_SERVICE_ACCOUNT_PATH); se omite el envío.');
      return;
    }
    if (tokens.length === 0) return;

    try {
      await admin.messaging(this.firebaseApp).sendEachForMulticast({
        tokens,
        notification: { title: notification.title, body: notification.body },
        data: notification.data,
      });
    } catch (error) {
      this.logger.error('Error enviando push de FCM', error as Error);
    }
  }
}
