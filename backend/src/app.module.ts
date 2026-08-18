import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdoptionCentersModule } from './adoption-centers/adoption-centers.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';
import { ReportsModule } from './reports/reports.module';
import { StorageModule } from './storage/storage.module';
import { UsersModule } from './users/users.module';
import { VetsModule } from './vets/vets.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    StorageModule,
    AuthModule,
    UsersModule,
    NotificationsModule,
    ReportsModule,
    ChatModule,
    AdoptionCentersModule,
    VetsModule,
  ],
})
export class AppModule {}
