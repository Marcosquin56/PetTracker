import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UnsupportedMediaTypeException,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { RateUserDto } from './dto/rate-user.dto';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { SearchUsersDto } from './dto/search-users.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';

const MAX_PHOTO_BYTES = 8 * 1024 * 1024; // 8MB
const ALLOWED_PHOTO_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic']);

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

  @Post('me/photo')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_PHOTO_BYTES },
      fileFilter: (_req, file, callback) => {
        if (!ALLOWED_PHOTO_MIME_TYPES.has(file.mimetype)) {
          callback(new UnsupportedMediaTypeException('Solo se aceptan fotos JPEG, PNG, WEBP o HEIC.'), false);
          return;
        }
        callback(null, true);
      },
    }),
  )
  updateMyPhoto(@CurrentUser() user: JwtPayload, @UploadedFile() file: Express.Multer.File) {
    return this.usersService.updatePhoto(user.sub, file);
  }

  @Post('me/fcm-tokens')
  addFcmToken(@CurrentUser() user: JwtPayload, @Body() dto: RegisterFcmTokenDto) {
    return this.usersService.addFcmToken(user.sub, dto.token);
  }

  @Delete('me/fcm-tokens/:token')
  removeFcmToken(@CurrentUser() user: JwtPayload, @Param('token') token: string) {
    return this.usersService.removeFcmToken(user.sub, token);
  }

  // Declarada antes de `:id` — si no, Nest matchea "search" como un :id.
  @Get('search')
  search(@CurrentUser() user: JwtPayload, @Query() query: SearchUsersDto) {
    return this.usersService.search(query.q, user.sub);
  }

  @Get(':id')
  getProfile(@Param('id') id: string) {
    return this.usersService.getPublicProfile(id);
  }

  @Get(':id/ratings')
  getRatings(@Param('id') id: string) {
    return this.usersService.getRatings(id);
  }

  @Post(':id/ratings')
  rateUser(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: RateUserDto) {
    return this.usersService.rateUser(user.sub, id, dto);
  }
}
