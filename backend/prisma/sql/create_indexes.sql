-- Índices GIST para las consultas de cercanía de ReportsService.findNearby()
-- y NotificationsService.notifyNearbyUsers(). Prisma no soporta índices de
-- expresión en su schema declarativo, así que se corren a mano una sola vez
-- después de la primera migración:
--
--   npx prisma db execute --file prisma/sql/create_indexes.sql --schema prisma/schema.prisma

CREATE INDEX IF NOT EXISTS pet_reports_geo_idx
  ON "pet_reports"
  USING GIST (ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326));

CREATE INDEX IF NOT EXISTS users_geo_idx
  ON "users"
  USING GIST (ST_SetSRID(ST_MakePoint("lastKnownLongitude", "lastKnownLatitude"), 4326))
  WHERE "lastKnownLatitude" IS NOT NULL AND "lastKnownLongitude" IS NOT NULL;
