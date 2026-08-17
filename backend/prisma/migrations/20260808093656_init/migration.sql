-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";

-- CreateEnum
CREATE TYPE "PetSpecies" AS ENUM ('cat', 'dog');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('lost', 'stray', 'found');

-- CreateEnum
CREATE TYPE "HealthCondition" AS ENUM ('healthy', 'injured', 'hungry', 'sick', 'has_collar', 'pregnant', 'aggressive', 'other');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "displayName" TEXT,
    "photoUrl" TEXT,
    "phoneNumber" TEXT,
    "lastKnownLatitude" DOUBLE PRECISION,
    "lastKnownLongitude" DOUBLE PRECISION,
    "lastKnownAddress" TEXT,
    "notificationRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "notificationsEnabled" BOOLEAN NOT NULL DEFAULT true,
    "fcmTokens" TEXT[],
    "refreshTokenHash" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pet_reports" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "species" "PetSpecies" NOT NULL,
    "status" "ReportStatus" NOT NULL,
    "healthConditions" "HealthCondition"[],
    "photoUrls" TEXT[],
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "address" TEXT,
    "petName" TEXT,
    "breed" TEXT,
    "color" TEXT,
    "description" TEXT,
    "contactPhone" TEXT,
    "isResolved" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pet_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "pet_reports_reporterId_idx" ON "pet_reports"("reporterId");

-- AddForeignKey
ALTER TABLE "pet_reports" ADD CONSTRAINT "pet_reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

