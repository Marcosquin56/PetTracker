import { Controller, Get, Param, Query } from '@nestjs/common';
import { NearbyQueryDto } from '../common/dto/nearby-query.dto';
import { AdoptionCentersService } from './adoption-centers.service';

/** Info de contacto pública, sin guard: no hay CRUD de usuario, solo lectura. */
@Controller('adoption-centers')
export class AdoptionCentersController {
  constructor(private readonly adoptionCentersService: AdoptionCentersService) {}

  @Get()
  findAll() {
    return this.adoptionCentersService.findAll();
  }

  @Get('nearby')
  findNearby(@Query() query: NearbyQueryDto) {
    return this.adoptionCentersService.findNearby(query);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.adoptionCentersService.findById(id);
  }
}
