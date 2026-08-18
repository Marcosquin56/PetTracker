import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Set chico de íconos dibujados a mano (trazo, sin relleno) para
/// reemplazar los íconos Material genéricos en los lugares más visibles
/// de la app — ver el concepto de diseño. `currentColor` en el SVG se
/// resuelve al `color` pasado acá vía colorFilter.
enum AppIcon {
  home('assets/icons/nav/home.svg'),
  map('assets/icons/nav/map.svg'),
  aliados('assets/icons/nav/aliados.svg'),
  chat('assets/icons/nav/chat.svg'),
  profile('assets/icons/nav/profile.svg'),
  directions('assets/icons/nav/directions.svg'),
  phone('assets/icons/nav/phone.svg');

  const AppIcon(this.asset);

  final String asset;
}

class AppIconWidget extends StatelessWidget {
  const AppIconWidget(this.icon, {required this.color, this.size = 22, super.key});

  final AppIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
