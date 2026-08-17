import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Conversation, Message, PetSpecies, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface ConversationSummary {
  id: string;
  report: { id: string; petName: string | null; species: PetSpecies } | null;
  otherUser: { id: string; displayName: string | null; photoUrl: string | null };
  lastMessage: Message | null;
  updatedAt: Date;
}

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * El otro participante siempre es el dueño del reporte (`report.reporterId`)
   * — el cliente solo manda `reportId`, no un `otherUserId` arbitrario, para
   * no permitir arrancar chats con cualquiera.
   */
  async getOrCreateConversation(userId: string, reportId: string): Promise<Conversation> {
    const report = await this.prisma.petReport.findUnique({ where: { id: reportId } });
    if (!report) throw new NotFoundException('Reporte no encontrado.');
    if (report.reporterId === userId) {
      throw new ForbiddenException('No podés iniciar un chat sobre tu propio reporte.');
    }

    const [userAId, userBId] = [userId, report.reporterId].sort();

    const existing = await this.prisma.conversation.findUnique({
      where: { reportId_userAId_userBId: { reportId, userAId, userBId } },
    });
    if (existing) return existing;

    try {
      return await this.prisma.conversation.create({ data: { reportId, userAId, userBId } });
    } catch (error) {
      // Dos requests casi simultáneas (doble-tap en "Chatear", reconexión
      // del socket) pueden pasar el findUnique de arriba antes de que
      // cualquiera haya insertado — la segunda choca con el @@unique en vez
      // de encontrar la conversación ya creada por la primera.
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const conversation = await this.prisma.conversation.findUnique({
          where: { reportId_userAId_userBId: { reportId, userAId, userBId } },
        });
        if (conversation) return conversation;
      }
      throw error;
    }
  }

  /** Más recientes primero; paginar con `before` (createdAt del último mensaje ya visto). */
  async getMessages(
    conversationId: string,
    userId: string,
    take: number,
    before?: string,
  ): Promise<Message[]> {
    await this.assertParticipant(conversationId, userId);

    return this.prisma.message.findMany({
      where: {
        conversationId,
        ...(before && { createdAt: { lt: new Date(before) } }),
      },
      orderBy: { createdAt: 'desc' },
      take,
    });
  }

  /**
   * Además de crear el mensaje, "toca" `conversation.updatedAt` (no cambia
   * ningún otro campo) para poder ordenar `listConversations` por actividad
   * reciente, y devuelve el id del otro participante para que el gateway
   * pueda mandarle un push aunque no tenga el socket conectado a esta
   * conversación en este momento.
   */
  async createMessage(
    conversationId: string,
    senderId: string,
    content: string,
  ): Promise<{ message: Message; recipientId: string }> {
    const conversation = await this.getConversationOrThrow(conversationId);
    this.assertIsParticipant(conversation, senderId);

    const [message] = await this.prisma.$transaction([
      this.prisma.message.create({ data: { conversationId, senderId, content } }),
      this.prisma.conversation.update({ where: { id: conversationId }, data: { updatedAt: new Date() } }),
    ]);

    const recipientId = conversation.userAId === senderId ? conversation.userBId : conversation.userAId;
    return { message, recipientId };
  }

  async assertParticipant(conversationId: string, userId: string): Promise<void> {
    const conversation = await this.getConversationOrThrow(conversationId);
    this.assertIsParticipant(conversation, userId);
  }

  /** Conversaciones del usuario con el último mensaje, más reciente actividad primero. */
  async listConversations(userId: string): Promise<ConversationSummary[]> {
    const conversations = await this.prisma.conversation.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      orderBy: { updatedAt: 'desc' },
      include: {
        userA: { select: { id: true, displayName: true, photoUrl: true } },
        userB: { select: { id: true, displayName: true, photoUrl: true } },
        report: { select: { id: true, petName: true, species: true } },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });

    return conversations.map((conversation) => {
      const otherUser = conversation.userAId === userId ? conversation.userB : conversation.userA;
      return {
        id: conversation.id,
        report: conversation.report,
        otherUser,
        lastMessage: conversation.messages[0] ?? null,
        updatedAt: conversation.updatedAt,
      };
    });
  }

  private async getConversationOrThrow(conversationId: string): Promise<Conversation> {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversación no encontrada.');
    return conversation;
  }

  private assertIsParticipant(conversation: Conversation, userId: string): void {
    if (conversation.userAId !== userId && conversation.userBId !== userId) {
      throw new ForbiddenException('No sos parte de esta conversación.');
    }
  }
}
