import { IsString, IsUUID, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsUUID()
  uid!: string;

  @IsString()
  token!: string;

  @IsString()
  @MinLength(8)
  newPassword!: string;
}
