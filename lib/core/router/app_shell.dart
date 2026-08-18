import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/application/chat_providers.dart';
import '../theme/app_icons.dart';

/// Scaffold con la barra de navegación inferior (Inicio/Mapa/Aliados/Chats/
/// Perfil). Cada pestaña es un branch de `StatefulShellRoute.indexedStack`
/// con su propio Navigator, así el scroll/filtros de cada una sobrevive al
/// cambiar de pestaña — las rutas de detalle (reporte, chat, perfil ajeno,
/// etc.) siguen viviendo fuera del shell, a pantalla completa.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadChats = ref.watch(unreadChatsCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final inactiveColor = colorScheme.onSurfaceVariant;
    final activeColor = colorScheme.onPrimaryContainer;

    Widget navIcon(AppIcon icon, {required bool selected}) {
      return AppIconWidget(icon, color: selected ? activeColor : inactiveColor, size: 21);
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Volver a tocar la pestaña activa resetea su navegación interna
          // (p. ej. si estabas en un detalle dentro de esa pestaña).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: navIcon(AppIcon.home, selected: false),
            selectedIcon: navIcon(AppIcon.home, selected: true),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: navIcon(AppIcon.map, selected: false),
            selectedIcon: navIcon(AppIcon.map, selected: true),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: navIcon(AppIcon.aliados, selected: false),
            selectedIcon: navIcon(AppIcon.aliados, selected: true),
            label: 'Aliados',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: navIcon(AppIcon.chat, selected: false),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: navIcon(AppIcon.chat, selected: true),
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: navIcon(AppIcon.profile, selected: false),
            selectedIcon: navIcon(AppIcon.profile, selected: true),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
