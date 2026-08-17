import { Body, Controller, Get, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { AuthService } from './auth.service';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { renderResetPasswordPage } from './reset-password.page';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('forgot-password')
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    await this.authService.forgotPassword(dto.email);
    return { message: 'Si el email existe, te enviamos instrucciones para restablecer tu contraseña.' };
  }

  /**
   * Página mínima autocontenida (sin build de frontend aparte) a la que
   * apunta el link del email: el usuario la abre desde el celular, pone la
   * contraseña nueva y el fetch() inline hace el POST a este mismo controller.
   */
  @Get('reset-password')
  resetPasswordPage(@Query('uid') uid: string, @Query('token') token: string, @Res() res: Response) {
    res.type('html').send(renderResetPasswordPage({ uid, token }));
  }

  @Post('reset-password')
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.authService.resetPassword(dto.uid, dto.token, dto.newPassword);
    return { message: 'Contraseña actualizada. Ya podés iniciar sesión con la nueva.' };
  }
}
