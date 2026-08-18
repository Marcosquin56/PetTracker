import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Resend (API HTTP) en vez de SMTP crudo: Render bloquea el tráfico saliente
 * por el puerto SMTP (confirmado con ENETUNREACH y después "Connection
 * timeout" incluso forzando IPv4), así que un socket SMTP nunca conecta ahí.
 * La API de Resend viaja por HTTPS, que sí sale sin bloqueos.
 *
 * Sin RESEND_API_KEY configurada, el link se imprime en el log en vez de
 * fallar: permite probar el flujo de "olvidé mi contraseña" en dev sin key.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly apiKey: string | undefined;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    this.apiKey = this.config.get<string>('RESEND_API_KEY') || undefined;
    this.from = this.config.get<string>('MAIL_FROM', 'PetTracker <no-reply@pettracker.app>');
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

    if (!this.apiKey) {
      this.logger.warn(
        `RESEND_API_KEY no configurada. Link de recuperación para ${to}: ${resetUrl}`,
      );
      return;
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from: this.from, to, subject, html }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Resend respondió ${response.status}: ${body}`);
    }
  }
}
