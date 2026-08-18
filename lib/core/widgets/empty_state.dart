import 'package:flutter/material.dart';

/// Estado vacío/error genérico (ícono + mensaje + reintentar opcional),
/// reusado por las listas de reportes, vets, casas de adopción y perfil.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.message, this.onRetry, super.key});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
