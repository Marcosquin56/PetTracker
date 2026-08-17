import { randomBytes } from 'node:crypto';
import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hora

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/** Reemplaza a Firebase Auth: registro/login con bcrypt + JWT access+refresh. */
@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly mailService: MailService,
  ) {}

  async register(dto: RegisterDto): Promise<TokenPair> {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('Ya existe una cuenta con ese email.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: { email: dto.email, passwordHash, displayName: dto.displayName },
    });

    return this.issueTokens(user.id, user.email);
  }

  async login(dto: LoginDto): Promise<TokenPair> {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Credenciales inválidas.');
    }

    return this.issueTokens(user.id, user.email);
  }

  /**
   * Rota el refresh token en cada uso: revisa que la firma/expiración sea
   * válida Y que coincida con el hash guardado (así un token robado deja de
   * servir apenas el dueño real vuelve a hacer login/refresh).
   */
  async refresh(refreshToken: string): Promise<TokenPair> {
    let payload: { sub: string; email: string };
    try {
      payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Refresh token inválido o expirado.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user?.refreshTokenHash || !(await bcrypt.compare(refreshToken, user.refreshTokenHash))) {
      throw new UnauthorizedException('Refresh token inválido o expirado.');
    }

    return this.issueTokens(user.id, user.email);
  }

  /**
   * No revela si el email existe o no (evita que alguien use este endpoint
   * para averiguar qué emails están registrados): siempre resuelve OK, y
   * solo manda el correo si encuentra un usuario con ese email.
   */
  async forgotPassword(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      return;
    }

    const rawToken = randomBytes(32).toString('hex');
    const resetPasswordTokenHash = await bcrypt.hash(rawToken, 10);
    const resetPasswordTokenExpiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MS);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { resetPasswordTokenHash, resetPasswordTokenExpiresAt },
    });

    const appUrl = this.config.get<string>('APP_PUBLIC_URL', '').replace(/\/$/, '');
    const resetUrl = `${appUrl}/auth/reset-password?uid=${user.id}&token=${rawToken}`;
    await this.mailService.sendPasswordReset(user.email, resetUrl);
  }

  /** Invalida el token usado y cualquier sesión activa (refresh token) del usuario. */
  async resetPassword(uid: string, rawToken: string, newPassword: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: uid } });
    const tokenIsValid =
      user?.resetPasswordTokenHash &&
      user.resetPasswordTokenExpiresAt &&
      user.resetPasswordTokenExpiresAt > new Date() &&
      (await bcrypt.compare(rawToken, user.resetPasswordTokenHash));

    if (!tokenIsValid) {
      throw new UnauthorizedException('El enlace es inválido o ya expiró.');
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: uid },
      data: {
        passwordHash,
        resetPasswordTokenHash: null,
        resetPasswordTokenExpiresAt: null,
        refreshTokenHash: null,
      },
    });
  }

  private async issueTokens(userId: string, email: string): Promise<TokenPair> {
    const accessToken = await this.jwtService.signAsync(
      { sub: userId, email },
      {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get<string>('JWT_ACCESS_EXPIRES_IN', '15m'),
      },
    );
    const refreshToken = await this.jwtService.signAsync(
      { sub: userId, email },
      {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get<string>('JWT_REFRESH_EXPIRES_IN', '30d'),
      },
    );

    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshTokenHash },
    });

    return { accessToken, refreshToken };
  }
}
