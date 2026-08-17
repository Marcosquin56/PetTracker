import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Solo letras/números/punto, y como mucho 10 caracteres (cubre .jpeg, .heic, etc). */
const SAFE_EXTENSION = /^\.[a-zA-Z0-9]{1,10}$/;

/**
 * Reemplaza a Firebase Storage: sube fotos a MinIO (S3-compatible,
 * self-hosted vía docker-compose.yml), pero el cliente S3 sirve igual
 * contra AWS S3/R2 real en producción con solo cambiar las env vars.
 */
@Injectable()
export class StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBaseUrl: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.get<string>('S3_BUCKET', 'pettracker-photos');
    this.publicBaseUrl = this.config.get<string>('S3_PUBLIC_BASE_URL', '');
    this.client = new S3Client({
      endpoint: this.config.get<string>('S3_ENDPOINT'),
      region: this.config.get<string>('S3_REGION', 'us-east-1'),
      forcePathStyle: true,
      credentials: {
        accessKeyId: this.config.get<string>('S3_ACCESS_KEY_ID', ''),
        secretAccessKey: this.config.get<string>('S3_SECRET_ACCESS_KEY', ''),
      },
    });
  }

  /**
   * Devuelve la key del objeto (no la URL completa): `publicBaseUrl` es un
   * túnel temporal que cambia cada vez que se relanza cloudflared, así que
   * "horneada" en una URL absoluta quedaría rota apenas cambia. Se resuelve
   * a URL pública recién al leer (ver resolvePhotoUrl), siempre con el
   * `publicBaseUrl` vigente en ese momento.
   */
  async uploadPhoto(file: Express.Multer.File, folder: string): Promise<string> {
    // `file.originalname` es texto de usuario (viene del multipart que
    // sube el cliente): puede traer "/", "..", espacios o unicode raro. En
    // vez de sanitizarlo, se descarta y solo se conserva la extensión, así
    // no hay forma de que termine formando una key con subcarpetas
    // inesperadas o una URL pública rota.
    const ext = extname(file.originalname).toLowerCase();
    const safeExt = SAFE_EXTENSION.test(ext) ? ext : '';
    const key = `${folder}/${randomUUID()}${safeExt}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );

    return key;
  }

  resolvePhotoUrl(key: string): string {
    return `${this.publicBaseUrl}/${key}`;
  }
}
