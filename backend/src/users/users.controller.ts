import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';

@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getMe(@CurrentUser() user: JwtPayload) {
    return this.usersService.findById(user.sub);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: JwtPayload, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.sub, dto);
  }

  @Post('me/fcm-tokens')
  addFcmToken(@CurrentUser() user: JwtPayload, @Body() dto: RegisterFcmTokenDto) {
    return this.usersService.addFcmToken(user.sub, dto.token);
  }

  @Delete('me/fcm-tokens/:token')
  removeFcmToken(@CurrentUser() user: JwtPayload, @Param('token') token: string) {
    return this.usersService.removeFcmToken(user.sub, token);
  }
}
