import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/widgets/empty_state.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reports/application/reports_providers.dart';
import '../../application/profile_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/reports_grid.dart';

/// Perfil ajeno (`/profile/:userId`) — mismo layout que el propio, sin
/// edición, con un botón para calificar al usuario (solo funciona si
/// compartís un chat con él — el backend es la fuente de verdad de esa
/// regla, ver UsersService.rateUser).
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  Future<void> _openRatingDialog(BuildContext context, WidgetRef ref) async {
    var score = 5;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Calificar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => score = starValue),
                    icon: Icon(
                      starValue <= score ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
                maxLength: 500,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Calificar')),
          ],
        ),
      ),
    );
    if (result != true || !context.mounted) return;

    try {
      await ref
          .read(profileRepositoryProvider)
          .rateUser(userId, score: score, comment: commentController.text.trim());
      ref.invalidate(userProfileProvider(userId));
      ref.invalidate(userRatingsProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gracias por calificar!')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo calificar.\n$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final reportsAsync = ref.watch(reportsByReporterProvider(userId));
    final ratingsAsync = ref.watch(userRatingsProvider(userId));
    final isSelf = ref.watch(authControllerProvider).valueOrNull?.uid == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider(userId));
            ref.invalidate(reportsByReporterProvider(userId));
            ref.invalidate(userRatingsProvider(userId));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(displayName: profile.displayName, photoUrl: profile.photoUrl),
              ),
              SliverToBoxAdapter(
                child: ProfileStatsRow(
                  reportsCount: profile.reportsCount,
                  ratingAverage: profile.ratingAverage,
                  ratingCount: profile.ratingCount,
                ),
              ),
              if (!isSelf)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openRatingDialog(context, ref),
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Calificar'),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Text('Reportes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              reportsAsync.when(
                data: (reports) => reports.isEmpty
                    ? const SliverToBoxAdapter(
                        child: EmptyState(icon: Icons.pets_outlined, message: 'Todavía no reportó ninguna mascota.'),
                      )
                    : ReportsGrid(reports: reports),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: EmptyState(icon: Icons.error_outline, message: 'No se pudieron cargar los reportes.\n$error'),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Text('Calificaciones', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              ratingsAsync.when(
                data: (ratings) => ratings.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Todavía no tiene calificaciones.'),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: ratings.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final rating = ratings[index];
                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating.score ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            title: Text(rating.raterName ?? 'Usuario'),
                            subtitle: rating.comment != null ? Text(rating.comment!) : null,
                            trailing: Text(
                              timeago.format(rating.createdAt, locale: 'es'),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (error, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          message: 'No se pudo cargar el perfil.\n$error',
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
      ),
    );
  }
}
