import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { StorageService } from '../storage/storage.service';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { CreateAttachmentDto } from './dto/create-attachment.dto';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { MessagesQueryDto } from './dto/messages-query.dto';

const MAX_ATTACHMENT_BYTES = 20 * 1024 * 1024; // 20MB

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
    private readonly storage: StorageService,
  ) {}

  @Post('conversations')
  createConversation(@CurrentUser() user: JwtPayload, @Body() dto: CreateConversationDto) {
    return this.chatService.getOrCreateConversation(user.sub, dto.reportId);
  }

  @Get('conversations')
  listConversations(@CurrentUser() user: JwtPayload) {
    return this.chatService.listConversations(user.sub);
  }

  @Get('conversations/:id/messages')
  getMessages(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Query() query: MessagesQueryDto,
  ) {
    return this.chatService.getMessages(id, user.sub, query.take, query.before);
  }

  @Post('conversations/:id/read')
  @HttpCode(204)
  markAsRead(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.chatService.markAsRead(id, user.sub);
  }

  /**
   * Foto/audio/archivo del chat. Va por REST (no por el socket, como el
   * texto) porque subir un archivo por WebSocket no tiene mucho sentido;
   * una vez subido y creado el mensaje, se reusa `ChatGateway.broadcast`
   * para que llegue en vivo y dispare el push igual que un mensaje de texto.
   */
  @Post('conversations/:id/attachments')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_ATTACHMENT_BYTES } }))
  async addAttachment(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: CreateAttachmentDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Falta el archivo.');

    const key = await this.storage.uploadPhoto(file, 'chat');
    const { message, recipientId } = await this.chatService.createMessage(id, user.sub, {
      content: dto.caption?.trim() ?? '',
      type: dto.type,
      attachmentKey: key,
      attachmentName: file.originalname,
      attachmentMimeType: file.mimetype,
      attachmentDurationMs: dto.durationMs,
    });
    this.chatGateway.broadcast(id, message, recipientId);
    return message;
  }
}
