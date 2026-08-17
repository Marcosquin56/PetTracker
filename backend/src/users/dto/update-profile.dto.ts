import { Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, IsString, Max, Min, ValidateNested } from 'class-validator';
import { LocationDto } from '../../common/dto/location.dto';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocationDto)
  lastKnownLocation?: LocationDto;

  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(100)
  notificationRadiusKm?: number;

  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;
}
