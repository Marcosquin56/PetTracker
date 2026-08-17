import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { Logger, Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

export const FIREBASE_ADMIN = 'FIREBASE_ADMIN';

const logger = new Logger('FirebaseAdmin');

/**
 * Única pieza de Firebase que sobrevive en el backend: el Admin SDK para
 * enviar push vía FCM. No toca Firestore/Storage/Auth — solo mensajería.
 *
 * Si no hay service-account configurada todavía (ver backend/README.md),
 * devuelve `null` en vez de tumbar el arranque completo: auth/reports/users
 * deben seguir funcionando aunque el push esté deshabilitado.
 */
export const firebaseAdminProvider: Provider = {
  provide: FIREBASE_ADMIN,
  inject: [ConfigService],
  useFactory: (config: ConfigService): admin.app.App | null => {
    if (admin.apps.length > 0) {
      return admin.app();
    }

    const serviceAccountPath = config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
    if (!serviceAccountPath || !existsSync(resolve(serviceAccountPath))) {
      logger.warn(
        'FIREBASE_SERVICE_ACCOUNT_PATH no configurado o el archivo no existe: ' +
          'las notificaciones push quedan deshabilitadas hasta configurarlo.',
      );
      return null;
    }

    return admin.initializeApp({
      credential: admin.credential.cert(require(resolve(serviceAccountPath))),
    });
  },
};
