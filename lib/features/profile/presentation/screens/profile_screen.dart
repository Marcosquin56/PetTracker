import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reports/application/reports_providers.dart';
import '../../application/profile_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/reports_grid.dart';

/// Pestaña "Perfil": perfil propio, con edición de nombre/foto, stats
/// (reportes/reputación/calificaciones), la grilla de "Mis reportes" y los
/// accesos que antes vivían en el menú del home (notificaciones, logout).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (photo == null) return;
    await ref.read(authControllerProvider.notifier).updatePhoto(photo);
  }

  Future<void> _editDisplayName(BuildContext context, WidgetRef ref, String? current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == current) return;
    await ref.read(authControllerProvider.notifier).updateProfile(displayName: newName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;

    if (me == null) {
      // No debería pasar (esta pestaña solo es alcanzable logueado), pero
      // evita un null-check feo mientras el logout todavía está en vuelo.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(userProfileProvider(me.uid));
    final reportsAsync = ref.watch(reportsByReporterProvider(me.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider(me.uid));
          ref.invalidate(reportsByReporterProvider(me.uid));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ProfileHeader(
                displayName: me.displayName,
                photoUrl: me.photoUrl,
                onEditPhoto: () => _changePhoto(context, ref),
                onEditName: () => _editDisplayName(context, ref, me.displayName),
              ),
            ),
            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) => ProfileStatsRow(
                  reportsCount: profile.reportsCount,
                  ratingAverage: profile.ratingAverage,
                  ratingCount: profile.ratingCount,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No se pudieron cargar tus estadísticas.\n$error', textAlign: TextAlign.center),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text('Mis reportes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            reportsAsync.when(
              data: (reports) => reports.isEmpty
                  ? const SliverToBoxAdapter(
                      child: EmptyState(icon: Icons.pets_outlined, message: 'Todavía no reportaste ninguna mascota.'),
                    )
                  : ReportsGrid(reports: reports),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: EmptyState(icon: Icons.error_outline, message: 'No se pudieron cargar tus reportes.\n$error'),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }
}
