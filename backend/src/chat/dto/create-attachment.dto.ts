import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { MessageType } from '@prisma/client';

/** `text` queda afuera a propósito: ese tipo se manda por el socket (ChatGateway), no acá. */
const ATTACHMENT_TYPES: MessageType[] = ['image', 'audio', 'file'];

export class CreateAttachmentDto {
  @IsIn(ATTACHMENT_TYPES)
  type!: MessageType;

  @IsOptional()
  @IsString()
  caption?: string;

  /** Solo para type "audio", duración grabada en milisegundos. */
  @IsOptional()
  @Transform(({ value }) => parseInt(value as string, 10))
  @IsInt()
  @Min(0)
  durationMs?: number;
}
