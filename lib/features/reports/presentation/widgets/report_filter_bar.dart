import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reports_feed_controller.dart';
import '../../domain/entities/enums/pet_species.dart';
import '../../domain/entities/enums/report_status.dart';
import '../utils/status_style.dart';

class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(reportFiltersProvider);
    final notifier = ref.read(reportFiltersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: filters.species == null,
              onSelected: (_) => notifier.update((s) => s.copyWith(clearSpecies: true)),
            ),
            const SizedBox(width: 8),
            for (final species in PetSpecies.values) ...[
              ChoiceChip(
                label: Text('${species.emoji} ${species.label}'),
                selected: filters.species == species,
                onSelected: (_) => notifier.update((s) => s.copyWith(species: species)),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 24,
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Todos'),
              selected: filters.status == null,
              onSelected: (_) => notifier.update((s) => s.copyWith(clearStatus: true)),
            ),
            const SizedBox(width: 8),
            for (final status in ReportStatus.values) ...[
              ChoiceChip(
                avatar: filters.status == status
                    ? Icon(status.icon, size: 16, color: status.color)
                    : null,
                label: Text(status.label),
                selected: filters.status == status,
                selectedColor: status.color.withValues(alpha: 0.16),
                onSelected: (_) => notifier.update((s) => s.copyWith(status: status)),
              ),
              const SizedBox(width: 8),
            ],
            ActionChip(
              avatar: const Icon(Icons.social_distance, size: 16),
              label: Text('${filters.radiusKm.toStringAsFixed(0)} km'),
              onPressed: () => _showRadiusSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showRadiusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(reportFiltersProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Radio de búsqueda', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${filters.radiusKm.toStringAsFixed(0)} km a la redonda',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Slider(
                    value: filters.radiusKm,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${filters.radiusKm.toStringAsFixed(0)} km',
                    onChanged: (value) => ref
                        .read(reportFiltersProvider.notifier)
                        .update((state) => state.copyWith(radiusKm: value)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
