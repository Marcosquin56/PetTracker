import 'package:flutter/material.dart';

/// Fila de 3 stats del perfil: Reportes / Reputación / Calificaciones —
/// mismo lugar que ocupaban "Mascotas/Reputación/Calificaciones" en el
/// mockup de referencia, adaptado a lo que la app realmente tiene
/// (historial de reportes en vez de un registro de mascotas propias).
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    required this.reportsCount,
    required this.ratingAverage,
    required this.ratingCount,
    super.key,
  });

  final int reportsCount;
  final double? ratingAverage;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(icon: Icons.pets, value: '$reportsCount', label: 'Reportes'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              value: ratingAverage != null ? ratingAverage!.toStringAsFixed(1) : '—',
              label: 'Reputación',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(icon: Icons.forum_outlined, value: '$ratingCount', label: 'Calificaciones'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
