import { Type } from 'class-transformer';
import { IsArray, IsEnum, IsOptional, IsString, ValidateNested } from 'class-validator';
import { HealthCondition, PetSpecies, ReportStatus } from '@prisma/client';
import { LocationDto } from '../../common/dto/location.dto';

export class CreateReportDto {
  @IsEnum(PetSpecies)
  species!: PetSpecies;

  @IsEnum(ReportStatus)
  status!: ReportStatus;

  @IsOptional()
  @IsArray()
  @IsEnum(HealthCondition, { each: true })
  healthConditions?: HealthCondition[];

  @ValidateNested()
  @Type(() => LocationDto)
  location!: LocationDto;

  @IsOptional() @IsString() petName?: string;
  @IsOptional() @IsString() breed?: string;
  @IsOptional() @IsString() color?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() contactPhone?: string;
}
