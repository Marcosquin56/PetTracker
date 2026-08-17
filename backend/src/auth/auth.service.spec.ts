import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';

// `bcrypt` expone `compare`/`hash` como propiedades no configurables del
// binding nativo: jest.spyOn no puede redefinirlas, así que se mockea el
// módulo entero en vez de espiar sus métodos.
jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed-password'),
  compare: jest.fn(),
}));

const mockedBcrypt = bcrypt as jest.Mocked<typeof bcrypt>;

// PrismaService extiende PrismaClient; para las pruebas unitarias alcanza
// con simular los métodos de `user` que AuthService realmente usa.
type MockPrisma = {
  user: {
    findUnique: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
};

describe('AuthService', () => {
  let authService: AuthService;
  let prisma: MockPrisma;
  let jwtService: JwtService;
  let mailService: { sendPasswordReset: jest.Mock };

  const user = {
    id: 'user-1',
    email: 'ana@example.com',
    passwordHash: 'hashed-password',
    refreshTokenHash: null as string | null,
    resetPasswordTokenHash: null as string | null,
    resetPasswordTokenExpiresAt: null as Date | null,
  };

  beforeEach(() => {
    mockedBcrypt.compare.mockReset();
    mockedBcrypt.hash.mockClear().mockResolvedValue('hashed-password' as never);

    prisma = {
      user: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    jwtService = {
      signAsync: jest.fn().mockResolvedValue('signed-token'),
      verifyAsync: jest.fn(),
    } as unknown as JwtService;

    mailService = { sendPasswordReset: jest.fn() };

    const config = {
      get: jest.fn((_key: string, defaultValue?: unknown) => defaultValue),
    } as unknown as ConfigService;

    authService = new AuthService(
      prisma as unknown as PrismaService,
      jwtService,
      config,
      mailService as unknown as MailService,
    );
  });

  describe('register', () => {
    it('rechaza el registro si ya existe un usuario con ese email', async () => {
      prisma.user.findUnique.mockResolvedValue(user);

      await expect(
        authService.register({ email: user.email, password: 'secret123', displayName: 'Ana' }),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(prisma.user.create).not.toHaveBeenCalled();
    });

    it('crea el usuario con la contraseña hasheada y devuelve un par de tokens', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({ ...user, passwordHash: 'anything' });
      prisma.user.update.mockResolvedValue(user);

      const tokens = await authService.register({
        email: user.email,
        password: 'secret123',
        displayName: 'Ana',
      });

      expect(prisma.user.create).toHaveBeenCalledTimes(1);
      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.passwordHash).not.toBe('secret123');
      expect(tokens).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
    });
  });

  describe('login', () => {
    it('rechaza credenciales cuando el usuario no existe', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        authService.login({ email: 'nadie@example.com', password: 'secret123' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rechaza credenciales cuando la contraseña no matchea el hash', async () => {
      prisma.user.findUnique.mockResolvedValue(user);
      mockedBcrypt.compare.mockResolvedValue(false as never);

      await expect(
        authService.login({ email: user.email, password: 'wrong-password' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('devuelve tokens cuando la contraseña matchea', async () => {
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      mockedBcrypt.compare.mockResolvedValue(true as never);

      const tokens = await authService.login({ email: user.email, password: 'secret123' });

      expect(tokens).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
    });
  });

  describe('refresh', () => {
    it('rechaza un refresh token con firma inválida', async () => {
      (jwtService.verifyAsync as jest.Mock).mockRejectedValue(new Error('bad signature'));

      await expect(authService.refresh('garbage-token')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rechaza un refresh token válido en firma pero que ya no matchea el hash guardado (rotado/robado)', async () => {
      (jwtService.verifyAsync as jest.Mock).mockResolvedValue({ sub: user.id, email: user.email });
      prisma.user.findUnique.mockResolvedValue({ ...user, refreshTokenHash: 'some-other-hash' });
      mockedBcrypt.compare.mockResolvedValue(false as never);

      await expect(authService.refresh('old-refresh-token')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rota el refresh token cuando el hash guardado matchea', async () => {
      (jwtService.verifyAsync as jest.Mock).mockResolvedValue({ sub: user.id, email: user.email });
      prisma.user.findUnique.mockResolvedValue({ ...user, refreshTokenHash: 'matching-hash' });
      prisma.user.update.mockResolvedValue(user);
      mockedBcrypt.compare.mockResolvedValue(true as never);

      const tokens = await authService.refresh('current-refresh-token');

      expect(tokens).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
      expect(prisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: user.id } }),
      );
    });
  });

  describe('forgotPassword', () => {
    it('no revela si el email no existe: resuelve OK sin mandar correo', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(authService.forgotPassword('nadie@example.com')).resolves.toBeUndefined();

      expect(prisma.user.update).not.toHaveBeenCalled();
      expect(mailService.sendPasswordReset).not.toHaveBeenCalled();
    });

    it('genera un token, lo guarda hasheado y manda el correo cuando el usuario existe', async () => {
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);

      await authService.forgotPassword(user.email);

      expect(prisma.user.update).toHaveBeenCalledTimes(1);
      const updateArgs = prisma.user.update.mock.calls[0][0];
      expect(updateArgs.data.resetPasswordTokenHash).toBeDefined();
      expect(updateArgs.data.resetPasswordTokenHash).not.toBe('');
      expect(mailService.sendPasswordReset).toHaveBeenCalledWith(user.email, expect.any(String));
    });
  });
});
