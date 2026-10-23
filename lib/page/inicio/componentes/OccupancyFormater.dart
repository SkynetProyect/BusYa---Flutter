import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

/// Interpreta el nivel de ocupación de un bus (ej. "50%", "0.5", "ROJO")
/// y lo traduce a texto y color para la UI.
class OccupancyFormatter {
  const OccupancyFormatter._();

  /// Texto legible: Lleno / Moderado / Vacío.
  static String label(String? nivel) {
    final ratio = parseRatio(nivel);
    if (ratio != null) {
      if (ratio > 0.8) return 'Lleno';
      if (ratio > 0.6) return 'Moderado';
      return 'Vacío';
    }
    switch (nivel?.toUpperCase()) {
      case 'ROJO':
        return 'Lleno';
      case 'NARANJA':
        return 'Moderado';
      default:
        return 'Vacío';
    }
  }

  /// Color asociado al nivel de ocupación.
  static Color color(String? nivel) {
    final ratio = parseRatio(nivel);
    if (ratio != null) {
      if (ratio > 0.8) return AppColors.error;
      if (ratio > 0.6) return AppColors.warning;
      return AppColors.success;
    }
    switch (nivel?.toUpperCase()) {
      case 'ROJO':
        return AppColors.error;
      case 'NARANJA':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  /// Color asociado al nivel de ocupación usando la paleta activa del tema.
  static Color themedColor(String? nivel, ColorScheme colors) {
    final ratio = parseRatio(nivel);
    if (ratio != null) {
      if (ratio > 0.8) return colors.error;
      if (ratio > 0.6) return colors.secondary;
      return colors.primary;
    }
    switch (nivel?.toUpperCase()) {
      case 'ROJO':
        return colors.error;
      case 'NARANJA':
        return colors.secondary;
      default:
        return colors.primary;
    }
  }

  /// Extrae un ratio [0..1] de cadenas como "50%", "0.5" o "75 %".
  /// Devuelve null si no es interpretable.
  static double? parseRatio(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    final match = RegExp(r'([0-9]+(?:[.,][0-9]+)?)').firstMatch(s);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) return null;

    // Con "%" explícito, o valores > 1, se interpreta como 0..100.
    if (s.contains('%') || value > 1.0) {
      return value.clamp(0.0, 100.0) / 100.0;
    }
    return value.clamp(0.0, 1.0);
  }
}
