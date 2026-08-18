import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/models/geo_location.dart';
import '../../application/vets_providers.dart';
import '../../domain/entities/vet_place_entity.dart';

/// Lista de veterinarias cercanas — usada por la pestaña Aliados. Vive como
/// widget aparte (no una pantalla con su propio Scaffold) para poder
/// mostrarse junto a `AdoptionCentersListView` bajo un solo AppBar/chips.
class VetsListView extends ConsumerWidget {
  const VetsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetsAsync = ref.watch(nearbyVetsProvider);

    return vetsAsync.when(
      data: (vets) {
        if (vets.isEmpty) {
          return EmptyState(
            icon: Icons.local_hospital_outlined,
            message: 'No encontramos veterinarias cerca en los próximos ${vetsSearchRadiusKm.toStringAsFixed(0)} km.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(nearbyVetsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: vets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _VetTile(vet: vets[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: error is LocationUnavailableException ? Icons.location_off_outlined : Icons.error_outline,
        message: error is LocationUnavailableException
            ? 'Activa el permiso de ubicación para ver las veterinarias más cercanas.'
            : 'No se pudo cargar el listado.\n$error',
        onRetry: () => ref.invalidate(nearbyVetsProvider),
      ),
    );
  }
}

class _VetTile extends StatelessWidget {
  const _VetTile({required this.vet});

  final VetPlaceEntity vet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => _showDetail(context, vet),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.local_hospital, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vet.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (vet.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        vet.address!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoChip(icon: Icons.place_outlined, label: '${vet.distanceKm.toStringAsFixed(1)} km'),
                        if (vet.rating != null)
                          _InfoChip(
                            icon: Icons.star_rounded,
                            label: vet.userRatingsTotal != null
                                ? '${vet.rating!.toStringAsFixed(1)} (${vet.userRatingsTotal})'
                                : vet.rating!.toStringAsFixed(1),
                          ),
                        if (vet.openNow != null)
                          _InfoChip(
                            icon: vet.openNow! ? Icons.check_circle_outline : Icons.schedule_outlined,
                            label: vet.openNow! ? 'Abierto ahora' : 'Cerrado ahora',
                            color: vet.openNow! ? Colors.green : colorScheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: effectiveColor)),
      ],
    );
  }
}

void _showDetail(BuildContext context, VetPlaceEntity vet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _VetDetailSheet(vet: vet),
  );
}

class _VetDetailSheet extends ConsumerWidget {
  const _VetDetailSheet({required this.vet});

  final VetPlaceEntity vet;

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo abrir el marcador telefónico.')));
    }
  }

  Future<void> _openDirections(BuildContext context, GeoLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(vetDetailProvider(vet.placeId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vet.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${vet.distanceKm.toStringAsFixed(1)} km de tu ubicación'),
            const SizedBox(height: 16),
            detailAsync.when(
              data: (detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.address != null) Text(detail.address!),
                  if (detail.openingHours != null) ...[
                    const SizedBox(height: 8),
                    ...detail.openingHours!.map((line) => Text(line, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (detail.phone != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _call(context, detail.phone!),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Llamar'),
                          ),
                        ),
                      if (detail.phone != null) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(context, vet.location),
                          icon: const Icon(Icons.directions_outlined),
                          label: const Text('Cómo llegar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No se pudo cargar el teléfono ni el horario.'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(context, vet.location),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Cómo llegar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
