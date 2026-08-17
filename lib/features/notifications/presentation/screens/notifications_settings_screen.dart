import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.valueOrNull;
    final notifier = ref.read(authControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SwitchListTile(
                      title: const Text('Avisarme de reportes cercanos'),
                      subtitle: const Text(
                        'Notificación push cuando alguien reporta un animal cerca de ti.',
                      ),
                      secondary: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
                      value: profile.notificationsEnabled,
                      onChanged: authState.isLoading
                          ? null
                          : (value) => notifier.updateProfile(notificationsEnabled: value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.social_distance, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Radio de aviso',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '${profile.notificationRadiusKm.toStringAsFixed(0)} km',
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Slider(
                          value: profile.notificationRadiusKm.clamp(1, 50),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${profile.notificationRadiusKm.toStringAsFixed(0)} km',
                          onChanged: (!profile.notificationsEnabled || authState.isLoading)
                              ? null
                              : (value) => notifier.updateProfile(notificationRadiusKm: value),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
