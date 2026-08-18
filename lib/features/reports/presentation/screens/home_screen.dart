import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../application/reports_feed_controller.dart';
import '../widgets/report_card.dart';
import '../widgets/report_filter_bar.dart';

/// Pestaña "Inicio": feed de reportes en grilla. El toggle a mapa se mudó a
/// su propia pestaña (`ReportsMapScreen`) y las acciones que antes vivían
/// en un menú del AppBar (veterinarias/adopción, chats, notificaciones,
/// cerrar sesión) ahora son pestañas propias o viven en Perfil.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(reportsFeedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 PetTracker'),
        actions: [
          IconButton(
            tooltip: 'Buscar personas',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReportFilterBar(),
          Expanded(
            child: feedState.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const EmptyState(
                    icon: Icons.pets,
                    message: 'No hay avistamientos cerca todavía.\n¡Sé el primero en reportar uno!',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(reportsFeedControllerProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportCard(
                        report: report,
                        onTap: () => context.push('/reports/${report.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                message: 'No se pudo cargar el feed.\n$error',
                onRetry: () => ref.read(reportsFeedControllerProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/new'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Reportar'),
      ),
    );
  }
}
