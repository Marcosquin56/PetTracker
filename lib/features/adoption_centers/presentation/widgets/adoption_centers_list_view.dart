import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../application/adoption_centers_providers.dart';
import '../../domain/entities/adoption_center_entity.dart';

/// Lista de casas de adopción — usada por la pestaña Aliados, mismo patrón
/// que `VetsListView` (widget sin Scaffold propio, para poder combinarse
/// bajo un solo AppBar/chips de categoría).
class AdoptionCentersListView extends ConsumerWidget {
  const AdoptionCentersListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(adoptionCentersProvider);

    return centersAsync.when(
      data: (centers) {
        if (centers.isEmpty) {
          return const EmptyState(
            icon: Icons.volunteer_activism_outlined,
            message: 'Todavía no hay casas de adopción cargadas.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adoptionCentersProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: centers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AdoptionCenterTile(center: centers[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        message: 'No se pudo cargar el listado.\n$error',
        onRetry: () => ref.invalidate(adoptionCentersProvider),
      ),
    );
  }
}

class _AdoptionCenterTile extends StatelessWidget {
  const _AdoptionCenterTile({required this.center});

  final AdoptionCenterEntity center;

  Future<void> _call(BuildContext context, String phone) => _launch(context, Uri(scheme: 'tel', path: phone));

  Future<void> _whatsapp(BuildContext context, String phone) {
    return _launch(context, Uri.parse('https://wa.me/${_toE164Paraguay(phone)}'));
  }

  Future<void> _email(BuildContext context, String email) => _launch(context, Uri(scheme: 'mailto', path: email));

  Future<void> _directions(BuildContext context) {
    final location = center.location;
    final uri = location != null
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}')
        : center.mapsUrl != null
            ? Uri.parse(center.mapsUrl!)
            : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(center.name)}');
    return _launch(context, uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launch(BuildContext context, Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    if (!await launchUrl(uri, mode: mode) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.tertiaryContainer,
                  foregroundImage:
                      center.photoUrl != null ? CachedNetworkImageProvider(center.photoUrl!) : null,
                  child: Icon(Icons.volunteer_activism, color: colorScheme.onTertiaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (center.address != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          center.address!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (center.distanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${center.distanceKm!.toStringAsFixed(1)} km de tu ubicación',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (center.phone != null)
                  OutlinedButton.icon(
                    onPressed: () => _call(context, center.phone!),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Llamar'),
                  ),
                if (center.whatsapp != null || center.phone != null)
                  OutlinedButton.icon(
                    onPressed: () => _whatsapp(context, center.whatsapp ?? center.phone!),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                if (center.email != null)
                  OutlinedButton.icon(
                    onPressed: () => _email(context, center.email!),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _directions(context),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Cómo llegar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// wa.me necesita el número en E.164 sin `+`. Los números que nos pasan son
/// paraguayos en formato local (con o sin el 0 inicial) — se asume ese país
/// ya que todas las casas cargadas hasta ahora son de Paraguay.
String _toE164Paraguay(String rawPhone) {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('595')) return digits;
  if (digits.startsWith('0')) return '595${digits.substring(1)}';
  return '595$digits';
}
