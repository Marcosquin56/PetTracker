import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../application/reports_feed_controller.dart';
import '../map/reports_map_view.dart';

/// Pestaña "Mapa": mismo feed que Inicio, pero como mapa a pantalla
/// completa — antes vivía como un toggle dentro de HomeScreen, ahora es su
/// propia pestaña de la barra inferior.
class ReportsMapScreen extends ConsumerWidget {
  const ReportsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(reportsFeedControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: feedState.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyState(
              icon: Icons.pets,
              message: 'No hay avistamientos cerca todavía.\n¡Sé el primero en reportar uno!',
            );
          }
          return ReportsMapView(
            reports: reports,
            onOpenDetail: (id) => context.push('/reports/$id'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          message: 'No se pudo cargar el mapa.\n$error',
          onRetry: () => ref.read(reportsFeedControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
