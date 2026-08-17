import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../application/reports_providers.dart';
import '../../domain/entities/pet_report_entity.dart';
import '../utils/status_style.dart';

class ReportCard extends ConsumerWidget {
  const ReportCard({required this.report, required this.onTap, super.key});

  final PetReportEntity report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(currentLocationProvider).valueOrNull;
    final distanceText =
        currentLocation != null ? '${report.distanceFromKm(currentLocation).toStringAsFixed(1)} km' : null;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = report.status.color;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  report.primaryPhotoUrl.isEmpty
                      ? Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Text(report.species.emoji, style: const TextStyle(fontSize: 40)),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: report.primaryPhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    // Row (en vez de dos Positioned top-left/top-right
                    // independientes) para que la pill de estado se achique
                    // con ellipsis cuando el label es largo ("Encontrado")
                    // en vez de superponerse con la de distancia.
                    child: Row(
                      children: [
                        Flexible(
                          child: _Pill(
                            color: statusColor,
                            icon: report.status.icon,
                            label: report.status.label,
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 6),
                          _Pill(color: Colors.black87, label: distanceText),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.species.emoji} ${report.petName ?? report.species.label}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(report.createdAt, locale: 'es'),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
