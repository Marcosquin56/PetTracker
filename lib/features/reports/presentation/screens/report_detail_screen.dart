import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../chat/application/chat_providers.dart';
import '../../application/reports_feed_controller.dart';
import '../../application/reports_providers.dart';
import '../../domain/entities/enums/health_condition.dart';
import '../../domain/entities/pet_report_entity.dart';
import '../utils/status_style.dart';
import '../widgets/section_label.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportByIdProvider(reportId));

    return Scaffold(
      body: reportAsync.when(
        data: (report) => _ReportDetailBody(report: report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar el reporte.\n$error')),
      ),
    );
  }
}

class _ReportDetailBody extends ConsumerStatefulWidget {
  const _ReportDetailBody({required this.report});

  final PetReportEntity report;

  @override
  ConsumerState<_ReportDetailBody> createState() => _ReportDetailBodyState();
}

class _ReportDetailBodyState extends ConsumerState<_ReportDetailBody> {
  PetReportEntity get report => widget.report;

  // Sin esto, un doble-tap dispara dos requests concurrentes (dos chats
  // de la misma conversación, o dos PATCH de resolución); el botón se
  // deshabilita mientras la primera sigue en vuelo.
  bool _isOpeningChat = false;
  bool _isMarkingResolved = false;

  Future<void> _callContact(BuildContext context) async {
    final phone = report.contactPhone;
    if (phone == null) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el marcador telefónico.')),
      );
    }
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversation = await ref.read(chatRepositoryProvider).getOrCreateConversation(report.id);
      if (!context.mounted) return;
      context.push('/chat/${conversation.id}');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo abrir el chat: $error')));
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _markResolved(BuildContext context, WidgetRef ref) async {
    if (_isMarkingResolved) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Ya se resolvió?'),
        content: const Text(
          'El reporte se oculta del feed y del mapa para los demás usuarios. No se puede deshacer desde la app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isMarkingResolved = true);
    try {
      await ref.read(reportRepositoryProvider).markResolved(report.id, true);
      ref.invalidate(reportsFeedControllerProvider);
      if (!context.mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por avisar! El reporte ya no aparece para otros usuarios.')),
      );
    } finally {
      if (mounted) setState(() => _isMarkingResolved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.uid;
    final isOwner = currentUserId != null && currentUserId == report.reporterId;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _PhotoCarousel(photoUrls: report.photoUrls),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${report.species.emoji} ${report.petName ?? report.species.label}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: report.status.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(report.status.icon, size: 15, color: report.status.color),
                            const SizedBox(width: 6),
                            Text(
                              report.status.label,
                              style: TextStyle(
                                color: report.status.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
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
                      if (report.breed != null) Chip(label: Text(report.breed!)),
                      if (report.color != null) Chip(label: Text(report.color!)),
                      for (final HealthCondition condition in report.healthConditions)
                        Chip(label: Text(condition.label)),
                    ],
                  ),
                  if (report.description != null) ...[
                    const SizedBox(height: 20),
                    const SectionLabel(icon: Icons.notes_outlined, label: 'Descripción'),
                    const SizedBox(height: 6),
                    Text(report.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 20),
                  const SectionLabel(icon: Icons.place_outlined, label: 'Ubicación'),
                  const SizedBox(height: 6),
                  if (report.location.address != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        report.location.address!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(report.location.latitude, report.location.longitude),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(report.id),
                            position: LatLng(report.location.latitude, report.location.longitude),
                          ),
                        },
                        zoomControlsEnabled: false,
                        liteModeEnabled: true,
                      ),
                    ),
                  ),
                  if (!isOwner) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isOpeningChat ? null : () => _openChat(context, ref),
                      icon: _isOpeningChat
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chatear'),
                    ),
                  ],
                  if (report.contactPhone != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _callContact(context),
                      icon: const Icon(Icons.phone),
                      label: Text('Llamar (${report.contactPhone})'),
                    ),
                  ],
                  if (isOwner && !report.isResolved) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isMarkingResolved ? null : () => _markResolved(context, ref),
                      icon: _isMarkingResolved
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.task_alt),
                      label: const Text('Ya se resolvió (ocultar reporte)'),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.pets, size: 64)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photoUrls.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: widget.photoUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
            );
          },
        ),
        // Scrim para que el back button y los puntos se lean sobre la foto.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black45],
              ),
            ),
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.photoUrls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == _page ? 1 : 0.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
