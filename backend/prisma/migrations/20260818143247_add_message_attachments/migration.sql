-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('text', 'image', 'audio', 'file');

-- AlterTable
ALTER TABLE "messages" ADD COLUMN     "attachmentDurationMs" INTEGER,
ADD COLUMN     "attachmentKey" TEXT,
ADD COLUMN     "attachmentMimeType" TEXT,
ADD COLUMN     "attachmentName" TEXT,
ADD COLUMN     "type" "MessageType" NOT NULL DEFAULT 'text';
