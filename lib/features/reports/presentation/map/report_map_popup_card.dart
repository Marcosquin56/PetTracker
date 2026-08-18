import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_icons.dart';
import '../../application/reports_providers.dart';
import '../../domain/entities/pet_report_entity.dart';
import '../utils/status_style.dart';

/// Mismo patrón que AdoptionCentersListView/VetsListView: Google Maps con
/// la ubicación como destino, la app de mapas del teléfono arma la ruta.
Future<void> _openDirections(BuildContext context, PetReportEntity report) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${report.location.latitude},${report.location.longitude}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir Google Maps.')),
    );
  }
}

/// Card que "salta" desde abajo cuando se toca un marker en el mapa —
/// resumen del reporte + acceso al detalle, sin abandonar el mapa.
class ReportMapPopupCard extends ConsumerWidget {
  const ReportMapPopupCard({
    required this.report,
    required this.onTap,
    required this.onClose,
    super.key,
  });

  final PetReportEntity report;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLocation = ref.watch(currentLocationProvider).valueOrNull;
    final distanceText =
        currentLocation != null ? '${report.distanceFromKm(currentLocation).toStringAsFixed(1)} km' : null;

    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: report.primaryPhotoUrl.isEmpty
                        ? Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Text(report.species.emoji, style: const TextStyle(fontSize: 28)),
                            ),
                          )
                        : CachedNetworkImage(imageUrl: report.primaryPhotoUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      Row(
                        children: [
                          Icon(report.status.icon, size: 14, color: report.status.color),
                          const SizedBox(width: 4),
                          Text(
                            report.status.label,
                            style: TextStyle(color: report.status.color, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const Spacer(),
                          if (distanceText != null)
                            Text(distanceText, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 2),
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
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: AppIconWidget(AppIcon.directions, color: colorScheme.primary, size: 19),
                  tooltip: 'Cómo llegar',
                  onPressed: () => _openDirections(context, report),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
