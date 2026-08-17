import { IsLatitude, IsLongitude, IsOptional, IsString } from 'class-validator';

/** Forma compartida por CreateReportDto y UpdateProfileDto (reports/users usan la misma ubicación anidada). */
export class LocationDto {
  @IsLatitude()
  latitude!: number;

  @IsLongitude()
  longitude!: number;

  @IsOptional()
  @IsString()
  address?: string;
}
