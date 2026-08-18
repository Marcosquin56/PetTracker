import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import type SMTPTransport from 'nodemailer/lib/smtp-transport';

/**
 * Sin SMTP_HOST configurado no hay forma de mandar correos reales, así que
 * en ese caso el link se imprime en el log del servidor en vez de fallar:
 * permite probar el flujo de "olvidé mi contraseña" en dev sin credenciales
 * SMTP a mano.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter: nodemailer.Transporter | null;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    this.from = this.config.get<string>('SMTP_FROM', 'PetTracker <no-reply@pettracker.app>');

    const host = this.config.get<string>('SMTP_HOST');
    if (!host) {
      this.transporter = null;
      return;
    }

    // `family` no está en los tipos de nodemailer pero SMTPConnection lo
    // reenvía tal cual a net.connect/tls.connect.
    const options: SMTPTransport.Options & { family?: number } = {
      host,
      port: this.config.get<number>('SMTP_PORT', 587),
      secure: this.config.get<string>('SMTP_SECURE', 'false') === 'true',
      // Algunos hosts (p. ej. Render) resuelven smtp.gmail.com a una IPv6 sin
      // salida real y el connect() cuelga varios minutos antes de tirar
      // ENETUNREACH. Forzamos IPv4, que sí tiene salida en esos entornos.
      family: 4,
      auth: {
        user: this.config.get<string>('SMTP_USER'),
        pass: this.config.get<string>('SMTP_PASS'),
      },
    };
    this.transporter = nodemailer.createTransport(options);
  }

  async sendPasswordReset(to: string, resetUrl: string): Promise<void> {
    const subject = 'Recuperá tu contraseña de PetTracker';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2>🐾 PetTracker</h2>
        <p>Pediste restablecer tu contraseña. Tocá el botón para elegir una nueva (el link vence en 1 hora):</p>
        <p>
          <a href="${resetUrl}" style="background:#8a4b32;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;display:inline-block;">
            Restablecer contraseña
          </a>
        </p>
        <p>Si no fuiste vos, podés ignorar este correo.</p>
      </div>
    `;

    if (!this.transporter) {
      this.logger.warn(
        `SMTP no configurado. Link de recuperación para ${to}: ${resetUrl}`,
      );
      return;
    }

    await this.transporter.sendMail({ from: this.from, to, subject, html });
  }
}
