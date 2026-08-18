import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/create_report_controller.dart';
import '../../application/reports_feed_controller.dart';
import '../../domain/entities/enums/health_condition.dart';
import '../../domain/entities/enums/pet_species.dart';
import '../../domain/entities/enums/report_status.dart';
import '../utils/status_style.dart';
import '../widgets/section_label.dart';

class CreateReportScreen extends ConsumerWidget {
  const CreateReportScreen({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final report = await ref.read(createReportControllerProvider.notifier).submit();
    if (report == null || !context.mounted) return;

    ref.invalidate(reportsFeedControllerProvider);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte creado. ¡Gracias por ayudar!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportControllerProvider);
    final notifier = ref.read(createReportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          const SectionLabel(icon: Icons.pets_outlined, label: 'Especie'),
          const SizedBox(height: 10),
          SegmentedButton<PetSpecies>(
            segments: PetSpecies.values
                .map((s) => ButtonSegment(value: s, label: Text('${s.emoji} ${s.label}')))
                .toList(),
            selected: {state.species},
            onSelectionChanged: (selection) => notifier.setSpecies(selection.first),
          ),
          const SizedBox(height: 24),
          const SectionLabel(icon: Icons.flag_outlined, label: 'Estado'),
          const SizedBox(height: 10),
          SegmentedButton<ReportStatus>(
            segments: ReportStatus.values
                .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                .toList(),
            selected: {state.status},
            onSelectionChanged: (selection) => notifier.setStatus(selection.first),
          ),
          const SizedBox(height: 24),
          const SectionLabel(icon: Icons.health_and_safety_outlined, label: 'Estado físico/salud'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthCondition.values.map((condition) {
              return FilterChip(
                label: Text(condition.label),
                selected: state.healthConditions.contains(condition),
                onSelected: (_) => notifier.toggleHealthCondition(condition),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const SectionLabel(icon: Icons.photo_camera_outlined, label: 'Fotos'),
          const SizedBox(height: 10),
          _PhotosPicker(photos: state.photos, notifier: notifier),
          const SizedBox(height: 24),
          const SectionLabel(icon: Icons.badge_outlined, label: 'Detalles'),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nombre de la mascota (opcional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onChanged: notifier.setPetName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Raza (opcional)',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
            onChanged: notifier.setBreed,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Color (opcional)',
              prefixIcon: Icon(Icons.palette_outlined),
            ),
            onChanged: notifier.setColor,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Descripción',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            onChanged: notifier.setDescription,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto (opcional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            onChanged: notifier.setContactPhone,
          ),
          const SizedBox(height: 24),
          const SectionLabel(icon: Icons.place_outlined, label: 'Ubicación'),
          const SizedBox(height: 10),
          _LocationTile(state: state, notifier: notifier),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: state.canSubmit ? () => _submit(context, ref) : null,
          child: state.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Publicar reporte'),
        ),
      ),
    );
  }
}

class _PhotosPicker extends StatelessWidget {
  const _PhotosPicker({required this.photos, required this.notifier});

  final List<XFile> photos;
  final CreateReportController notifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final photo in photos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(photo.path), width: 96, height: 96, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => notifier.removePhoto(photo),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black87,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _AddPhotoButton(icon: Icons.camera_alt_outlined, onTap: notifier.addPhotoFromCamera),
          const SizedBox(width: 8),
          _AddPhotoButton(icon: Icons.photo_library_outlined, onTap: notifier.addPhotoFromGallery),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Icon(icon, color: colorScheme.primary),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.state, required this.notifier});

  final CreateReportFormState state;
  final CreateReportController notifier;

  @override
  Widget build(BuildContext context) {
    if (state.isResolvingLocation) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Obteniendo tu ubicación...'),
      );
    }

    if (state.location == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.location_off, color: Theme.of(context).colorScheme.error),
        title: const Text('No pudimos obtener tu ubicación'),
        subtitle: const Text('Revisá que el GPS esté activo y que le diste permiso a la app. Tocá para reintentar.'),
        onTap: notifier.retryLocation,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
          title: Text(
            '${state.location!.latitude.toStringAsFixed(5)}, ${state.location!.longitude.toStringAsFixed(5)}',
          ),
          subtitle: const Text('Ubicación GPS actual'),
        ),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Dirección / referencia (opcional)',
            prefixIcon: Icon(Icons.edit_location_alt_outlined),
          ),
          onChanged: notifier.setAddress,
        ),
      ],
    );
  }
}
