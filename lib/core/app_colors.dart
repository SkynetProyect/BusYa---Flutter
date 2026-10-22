import 'package:flutter/material.dart';

/// Colores compartidos de marca para mantener la identidad visual consistente.
abstract final class AppColors {
  // Colores principales de marca.
  static const primary = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF2E7D32);
  static const green = Color(
    0xFF0FB981,
  ); // Verde BusYa, reservado para acentos.
  static const greenOnPrimary = Color(0xFF8CF0C8);
  static const greenDark = primary;

  // Fondos, superficies y contenedores.
  static const surface = Color(0xFFF6F7FB);
  static const surfaceMuted = Color(0xFFF8F8FA);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceMint = Color(0xFFE7F5EE);
  static const surfaceGreen = Color(0xFFE8F5E9);
  static const surfaceLavender = Color(0xFFF0EDF8);
  static const surfaceError = Color(0xFFFFF1F1);
  static const surfaceTransparent = Color(0x00000000);

  // Textos e iconos.
  static const text = Color(0xFF252B3A);
  static const textOnPrimary = surfaceWhite;
  static const textOnPrimaryMuted = Color(0xB3FFFFFF);
  static const textOnPrimarySubtle = Color(0x99FFFFFF);
  static const textSecondary = Color(0xFF68736D);
  static const textMuted = Color(0xFF9E9E9E);
  static const textSecondaryMuted = Color(0xFF757575);
  static const textTertiary = Color(0xFF616161);
  static const textBlack = Color(0xFF000000);
  static const textSubtle = textMuted;
  static const neutralLighter = Color(0xFFEEEEEE);
  static const neutralLight = Color(0xFFE0E0E0);
  static const neutralTrack = Color(0xFFE2E2E6);
  static const textDark = Color(0xDD000000);
  static const textMedium = Color(0x8A000000);
  static const textLight = Color(0x61000000);
  static const shadowSoft = Color(0x42000000);
  static const iconInactive = textSubtle;

  // Bordes, divisores y sombras.
  static const border = Color(0xFFEBECEF);
  static const borderSoft = Color(0xFFE4E9E5);
  static const shadow = Color(0xFF33304E);

  // Estados.
  static const success = Color(0xFF4CAF50);
  static const successLight = Color(0xFF66BB6A);
  static const successPale = Color(0xFF9CCC65);
  static const error = Color(0xFFF44336);
  static const errorLight = Color(0xFFE57373);
  static const errorAccent = Color(0xFFFF5252);
  static const warning = Color(0xFFFF9800);
  static const warningLight = Color(0xFFFFC107);
  static const info = Color(0xFF2196F3);

  // Colores específicos de componentes y datos.
  static const authHeading = Color(0xFF11192D);
  static const routeGreen = Color(0xFF2E7D5B);
  static const routeGreenLight = Color(0xFF8FD3B6);
  static const routePurple = Color(0xFF6B5B7B);
  static const routeMint = Color(0xFFA9DFC4);
  static const cardVisa = Color(0xFF1E5AB6);
  static const cardVisaDark = Color(0xFF0A3D91);
  static const cardMastercard = Color(0xFFF9A825);
  static const cardMastercardLight = Color(0xFFFBC02D);
  static const location = info;
  static const ecoAccent = Color(0xFFB2FF59);
  static const loadingTrack = Color(0x3DFFFFFF);
  static const topBarHighlight = Color(0xFFDF7C3B);
  static const topBarDeep = Color(0xFF191B96);
  static const overlayWhiteSubtle = Color(0x1EFFFFFF);
  static const routeSearchSurface = Color(0xFFF5F5F7);
  static const terminalPrimary = Color(0xFF529471);
  static const terminalNavigationStart = Color(0xFF3B9EDF);
  static const terminalNavigationEnd = Color(0xFF36D45E);
  static const terminalNavigationSurface = Color(0xFFE6E0E0);
}
