import { Controller, Get, Param, Query } from '@nestjs/common';
import { NearbyQueryDto } from '../common/dto/nearby-query.dto';
import { VetsService } from './vets.service';

@Controller('vets')
export class VetsController {
  constructor(private readonly vetsService: VetsService) {}

  @Get('nearby')
  findNearby(@Query() query: NearbyQueryDto) {
    return this.vetsService.findNearby(query);
  }

  @Get(':placeId')
  findDetail(@Param('placeId') placeId: string) {
    return this.vetsService.findDetail(placeId);
  }
}
