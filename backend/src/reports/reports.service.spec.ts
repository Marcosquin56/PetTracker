import { ForbiddenException } from '@nestjs/common';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { ReportsService } from './reports.service';

type MockPrisma = {
  petReport: {
    create: jest.Mock;
    findUnique: jest.Mock;
    findMany: jest.Mock;
    update: jest.Mock;
  };
  $queryRaw: jest.Mock;
};

describe('ReportsService', () => {
  let reportsService: ReportsService;
  let prisma: MockPrisma;
  let storage: { uploadPhoto: jest.Mock; resolvePhotoUrl: jest.Mock };
  let notifications: { notifyNearbyUsers: jest.Mock };

  const rawReport = {
    id: 'report-1',
    reporterId: 'user-1',
    species: 'dog',
    status: 'lost',
    healthConditions: [],
    photoUrls: ['reports/photo-1.jpg'],
    latitude: -34.6037,
    longitude: -58.3816,
    address: 'CABA',
    petName: 'Firulais',
    breed: null,
    color: null,
    description: null,
    contactPhone: null,
    isResolved: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(() => {
    prisma = {
      petReport: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
      $queryRaw: jest.fn(),
    };

    storage = {
      uploadPhoto: jest.fn(),
      resolvePhotoUrl: jest.fn((key: string) => `https://cdn.example.com/${key}`),
    };

    notifications = { notifyNearbyUsers: jest.fn().mockResolvedValue(undefined) };

    reportsService = new ReportsService(
      prisma as unknown as PrismaService,
      storage as unknown as StorageService,
      notifications as unknown as NotificationsService,
    );
  });

  describe('create', () => {
    const dto = {
      species: 'dog' as const,
      status: 'lost' as const,
      location: { latitude: -34.6037, longitude: -58.3816, address: 'CABA' },
      petName: 'Firulais',
    };

    it('anida la ubicación y resuelve las URLs de las fotos en la respuesta', async () => {
      prisma.petReport.create.mockResolvedValue(rawReport);

      const result = await reportsService.create('user-1', dto);

      expect(result.location).toEqual({
        latitude: rawReport.latitude,
        longitude: rawReport.longitude,
        address: rawReport.address,
      });
      expect(result.photoUrls).toEqual(['https://cdn.example.com/reports/photo-1.jpg']);
      expect((result as Record<string, unknown>).latitude).toBeUndefined();
    });

    it('no bloquea la respuesta al usuario mientras se notifica a los usuarios cercanos', async () => {
      let resolveNotify!: () => void;
      const pendingNotify = new Promise<void>((resolve) => {
        resolveNotify = resolve;
      });
      notifications.notifyNearbyUsers.mockReturnValue(pendingNotify);
      prisma.petReport.create.mockResolvedValue(rawReport);

      const result = await reportsService.create('user-1', dto);

      expect(result).toBeDefined();
      expect(notifications.notifyNearbyUsers).toHaveBeenCalledWith(rawReport);

      resolveNotify();
    });
  });

  describe('findNearby', () => {
    it('convierte radiusKm a metros y pasa lat/lng a la consulta PostGIS', async () => {
      prisma.$queryRaw.mockResolvedValue([{ ...rawReport, distanceKm: 1.23 }]);

      const results = await reportsService.findNearby({ lat: -34.6, lng: -58.4, radiusKm: 5 });

      const callArgs = prisma.$queryRaw.mock.calls[0];
      const substitutions = callArgs.slice(1);
      // lng, lat, lng, lat, radiusMeters (ver reports.service.ts findNearby)
      expect(substitutions).toEqual([-58.4, -34.6, -58.4, -34.6, 5000]);
      expect(results[0].distanceKm).toBe(1.23);
    });

    it('usa el radio por default cuando no se especifica radiusKm', async () => {
      prisma.$queryRaw.mockResolvedValue([]);

      await reportsService.findNearby({ lat: -34.6, lng: -58.4, radiusKm: 10 });

      const substitutions = prisma.$queryRaw.mock.calls[0].slice(1);
      expect(substitutions[4]).toBe(10000);
    });
  });

  describe('update', () => {
    it('rechaza editar un reporte de otro usuario', async () => {
      prisma.petReport.findUnique.mockResolvedValue(rawReport);

      await expect(
        reportsService.update(rawReport.id, 'otro-usuario', { petName: 'Otro nombre' }),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(prisma.petReport.update).not.toHaveBeenCalled();
    });

    it('permite editar un reporte propio', async () => {
      prisma.petReport.findUnique.mockResolvedValue(rawReport);
      prisma.petReport.update.mockResolvedValue({ ...rawReport, petName: 'Nuevo nombre' });

      const result = await reportsService.update(rawReport.id, rawReport.reporterId, {
        petName: 'Nuevo nombre',
      });

      expect(result.petName).toBe('Nuevo nombre');
    });
  });
});
