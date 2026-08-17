import 'package:flutter/material.dart';

import '../../domain/entities/enums/pet_species.dart';
import '../../domain/entities/enums/report_status.dart';

/// Colores/íconos semánticos por estado, separados del enum de dominio
/// (que debe seguir siendo Dart puro, sin depender de Flutter).
extension ReportStatusStyle on ReportStatus {
  Color get color {
    switch (this) {
      case ReportStatus.lost:
        return const Color(0xFFD32F2F);
      case ReportStatus.stray:
        return const Color(0xFFEF6C00);
      case ReportStatus.found:
        return const Color(0xFF2E7D32);
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
