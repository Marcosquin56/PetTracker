import { Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatService, MessageResponse } from './chat.service';

/** Etiqueta corta para el cuerpo del push cuando el mensaje no es texto. */
const ATTACHMENT_PREVIEW: Record<string, string> = {
  image: '📷 Foto',
  audio: '🎤 Mensaje de voz',
  file: '📎 Archivo',
};

interface AuthenticatedSocket extends Socket {
  data: { userId: string };
}

/**
 * Chat 1:1 en tiempo real. Auth manual en `handleConnection` (no hay un
 * equivalente directo a JwtAuthGuard para el ciclo de vida de conexión de
 * un Gateway) leyendo el JWT del handshake — mismo JWT_ACCESS_SECRET que
 * usa JwtStrategy para las rutas REST.
 */
@WebSocketGateway({ namespace: '/chat', cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection {
  private readonly logger = new Logger(ChatGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly notifications: NotificationsService,
  ) {}

  async handleConnection(client: AuthenticatedSocket): Promise<void> {
    try {
      const token = client.handshake.auth?.token as string | undefined;
      if (!token) throw new UnauthorizedException();

      const payload = await this.jwtService.verifyAsync<{ sub: string }>(token, {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      });
      client.data.userId = payload.sub;
    } catch {
      this.logger.warn(`Conexión de socket rechazada: ${client.id}`);
      client.disconnect();
    }
  }

  @SubscribeMessage('joinConversation')
  async joinConversation(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string },
  ): Promise<void> {
    await this.chatService.assertParticipant(data.conversationId, client.data.userId);
    await client.join(`conversation:${data.conversationId}`);
  }

  @SubscribeMessage('sendMessage')
  async sendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string; content: string },
  ): Promise<void> {
    const content = data.content?.trim();
    if (!content || content.length > 2000) return;

    const { message, recipientId } = await this.chatService.createMessage(data.conversationId, client.data.userId, {
      content,
    });
    this.broadcast(data.conversationId, message, recipientId);
  }

  /**
   * Emite el mensaje a quien tenga el socket conectado a esa conversación, y
   * empuja un push al otro participante (no bloquea si tarda o falla — el
   * push es la única forma de enterarse si no tiene esa conversación abierta
   * en este momento). Usado tanto por `sendMessage` (texto, vía socket) como
   * por `ChatController.addAttachment` (foto/audio/archivo, vía REST — subir
   * un archivo por un WebSocket no tiene mucho sentido).
   */
  broadcast(conversationId: string, message: MessageResponse, recipientId: string): void {
    this.server.to(`conversation:${conversationId}`).emit('newMessage', message);

    const preview = message.type === 'text' ? message.content : ATTACHMENT_PREVIEW[message.type];
    void this.notifications.notifyUser(recipientId, {
      title: 'Nuevo mensaje',
      body: preview.length > 120 ? `${preview.slice(0, 117)}...` : preview,
      data: { type: 'chat', conversationId },
    });
  }
}
