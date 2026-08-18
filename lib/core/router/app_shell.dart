import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/application/chat_providers.dart';

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
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Aliados',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
