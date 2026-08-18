-- AlterTable
ALTER TABLE "conversations" ADD COLUMN     "lastReadAtUserA" TIMESTAMP(3),
ADD COLUMN     "lastReadAtUserB" TIMESTAMP(3);
