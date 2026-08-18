import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold con la barra de navegación inferior (Inicio/Mapa/Aliados/Chats/
/// Perfil). Cada pestaña es un branch de `StatefulShellRoute.indexedStack`
/// con su propio Navigator, así el scroll/filtros de cada una sobrevive al
/// cambiar de pestaña — las rutas de detalle (reporte, chat, perfil ajeno,
/// etc.) siguen viviendo fuera del shell, a pantalla completa.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Aliados',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
