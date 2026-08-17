import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';
import '../../application/reports_feed_controller.dart';
import '../../application/reports_providers.dart';
import '../map/reports_map_view.dart';
import '../widgets/report_card.dart';
import '../widgets/report_filter_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(reportsFeedControllerProvider);
    final viewMode = ref.watch(reportsViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 PetTracker'),
        actions: [
          IconButton(
            tooltip: viewMode == ReportsViewMode.list ? 'Ver en mapa' : 'Ver en lista',
            icon: Icon(viewMode == ReportsViewMode.list ? Icons.map_outlined : Icons.view_list_outlined),
            onPressed: () => ref.read(reportsViewModeProvider.notifier).state =
                viewMode == ReportsViewMode.list ? ReportsViewMode.map : ReportsViewMode.list,
          ),
          IconButton(
            tooltip: 'Chats',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/settings/notifications'),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
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
                  return const _EmptyFeed();
                }

                if (viewMode == ReportsViewMode.map) {
                  return ReportsMapView(
                    reports: reports,
                    onOpenDetail: (id) => context.push('/reports/$id'),
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
              error: (error, _) => _FeedError(
                error: error,
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

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'No hay avistamientos cerca todavía.\n¡Sé el primero en reportar uno!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No se pudo cargar el feed.\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
