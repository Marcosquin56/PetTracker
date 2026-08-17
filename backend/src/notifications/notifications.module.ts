import { Module } from '@nestjs/common';
import { firebaseAdminProvider } from './firebase-admin.provider';
import { NotificationsService } from './notifications.service';

@Module({
  providers: [NotificationsService, firebaseAdminProvider],
  exports: [NotificationsService],
})
export class NotificationsModule {}
