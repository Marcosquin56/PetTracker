import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/enums/pet_species.dart';
import '../../domain/entities/enums/report_status.dart';

/// Colores/íconos semánticos por estado, separados del enum de dominio
/// (que debe seguir siendo Dart puro, sin depender de Flutter).
extension ReportStatusStyle on ReportStatus {
  Color get color {
    switch (this) {
      case ReportStatus.lost:
        return AppTheme.statusLost;
      case ReportStatus.stray:
        return AppTheme.statusStray;
      case ReportStatus.found:
        return AppTheme.statusFound;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.lost:
        return Icons.error_outline;
      case ReportStatus.stray:
        return Icons.visibility_outlined;
      case ReportStatus.found:
        return Icons.check_circle_outline;
    }
  }
}

extension PetSpeciesStyle on PetSpecies {
  String get emoji {
    switch (this) {
      case PetSpecies.dog:
        return '🐶';
      case PetSpecies.cat:
        return '🐱';
    }
  }
}
