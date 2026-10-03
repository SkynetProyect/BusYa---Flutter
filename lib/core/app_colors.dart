import 'package:flutter/material.dart';

/// Colores compartidos de marca para mantener la identidad visual consistente.
abstract final class AppColors {
  static const primary = Color(0xFF1B5E20); // Verde oscuro del botón Puntos Eco.
  static const primaryLight = Color(0xFF2E7D32);
  static const green = Color(0xFF0FB981); // Verde BusYa, reservado para acentos.
  static const greenOnPrimary = Color(0xFF8CF0C8);
  static const greenDark = primary;
  static const surface = Color(0xFFF6F7FB);
  static const text = Color(0xFF252B3A);
}
