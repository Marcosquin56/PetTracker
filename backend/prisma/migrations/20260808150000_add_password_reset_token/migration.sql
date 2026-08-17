-- AlterTable
ALTER TABLE "users" ADD COLUMN "resetPasswordTokenHash" TEXT,
ADD COLUMN "resetPasswordTokenExpiresAt" TIMESTAMP(3);
