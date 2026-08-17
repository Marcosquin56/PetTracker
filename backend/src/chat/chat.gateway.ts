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
import { ChatService } from './chat.service';

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

    const { message, recipientId } = await this.chatService.createMessage(
      data.conversationId,
      client.data.userId,
      content,
    );
    this.server.to(`conversation:${data.conversationId}`).emit('newMessage', message);

    // No bloquea el ack del socket si el push tarda o falla; el destinatario
    // puede no tener el socket conectado a esta conversación en este momento
    // (app en background, en otra pantalla), así que el push es la única
    // forma de que se entere en el momento.
    void this.notifications.notifyUser(recipientId, {
      title: 'Nuevo mensaje',
      body: content.length > 120 ? `${content.slice(0, 117)}...` : content,
      data: { type: 'chat', conversationId: data.conversationId },
    });
  }
}
