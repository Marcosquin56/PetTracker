import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../reports/domain/entities/pet_report_entity.dart';
import '../../../reports/presentation/widgets/report_card.dart';

/// Grilla de reportes para el perfil (propio o ajeno) — mismo `ReportCard`
/// y layout que el feed de Inicio, como `SliverGrid` porque vive dentro de
/// un `CustomScrollView` junto al header/stats del perfil.
class ReportsGrid extends StatelessWidget {
  const ReportsGrid({required this.reports, super.key});

  final List<PetReportEntity> reports;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final report = reports[index];
            return ReportCard(report: report, onTap: () => context.push('/reports/${report.id}'));
          },
          childCount: reports.length,
        ),
      ),
    );
  }
}
