import { Body, Controller, Get, HttpCode, Param, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { ChatService } from './chat.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { MessagesQueryDto } from './dto/messages-query.dto';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

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
}
