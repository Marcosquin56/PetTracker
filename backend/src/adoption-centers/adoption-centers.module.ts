import { Module } from '@nestjs/common';
import { AdoptionCentersController } from './adoption-centers.controller';
import { AdoptionCentersService } from './adoption-centers.service';

@Module({
  controllers: [AdoptionCentersController],
  providers: [AdoptionCentersService],
})
export class AdoptionCentersModule {}
