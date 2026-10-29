import 'package:flutter/material.dart';

/// Colores compartidos de marca para mantener la identidad visual de BusYa.
/// Incluye paletas para modo claro y modo oscuro.
abstract final class AppColors {
  // =========================================================
  // COLORES PRINCIPALES DE MARCA
  // =========================================================

  static const primary = Color(0xFF246B38);
  static const primaryLight = Color(0xFF3F8750);
  static const green = Color(0xFF3F8750);
  static const greenOnPrimary = Color(0xFFD8E9DA);
  static const greenDark = Color(0xFF194D2A);

  // =========================================================
  // FONDOS Y SUPERFICIES: MODO CLARO
  // =========================================================

  static const surface = Color(0xFFF4F6F5);
  static const surfaceMuted = Color(0xFFEBEFEC);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceMint = Color(0xFFE8F1E9);
  static const surfaceGreen = Color(0xFFDDEADD);
  static const surfaceLavender = Color(0xFFF0EFF3);
  static const surfaceError = Color(0xFFFAECEB);
  static const surfaceTransparent = Color(0x00000000);

  // =========================================================
  // FONDOS Y SUPERFICIES: MODO OSCURO
  // =========================================================

  static const darkBackground = Color(0xFF10151D);
  static const darkSurface = Color(0xFF1D252D);
  static const darkSurfaceElevated = Color(0xFF27313A);
  static const darkSurfaceMuted = Color(0xFF222B32);
  static const darkSurfaceGreen = Color(0xFF20372A);
  static const darkSurfaceError = Color(0xFF3A2425);
  static const darkBorder = Color(0xFF37423D);

  // =========================================================
  // TEXTOS E ICONOS: MODO CLARO
  // =========================================================

  static const text = Color(0xFF202923);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnPrimaryMuted = Color(0xB3FFFFFF);
  static const textOnPrimarySubtle = Color(0x99FFFFFF);
  static const textSecondary = Color(0xFF626D66);
  static const textMuted = Color(0xFF89928C);
  static const textSecondaryMuted = Color(0xFF737C76);
  static const textTertiary = Color(0xFF535D56);
  static const textBlack = Color(0xFF000000);
  static const textSubtle = textMuted;

  // =========================================================
  // TEXTOS E ICONOS: MODO OSCURO
  // =========================================================

  static const darkText = Color(0xFFE7ECE9);
  static const darkTextSecondary = Color(0xFFB1BDB5);
  static const darkTextMuted = Color(0xFF89968E);
  static const darkIconInactive = Color(0xFF89968E);

  // =========================================================
  // COLORES NEUTROS Y COMPATIBILIDAD
  // =========================================================

  static const neutralLighter = Color(0xFFF0F2F0);
  static const neutralLight = Color(0xFFDCE2DD);
  static const neutralTrack = Color(0xFFD9DFDB);

  static const textDark = Color(0xDD000000);
  static const textMedium = Color(0x8A000000);
  static const textLight = Color(0x61000000);

  static const shadowSoft = Color(0x30000000);
  static const iconInactive = textSubtle;

  // =========================================================
  // BORDES, DIVISORES Y SOMBRAS
  // =========================================================

  static const border = Color(0xFFE0E5E1);
  static const borderSoft = Color(0xFFD7E0D8);
  static const shadow = Color(0xFF202923);

  static const darkShadow = Color(0x99000000);
  static const darkDivider = Color(0xFF303A42);

  // =========================================================
  // ESTADOS: ÉXITO
  // =========================================================

  static const success = Color(0xFF38834A);
  static const successLight = Color(0xFF5B9B67);
  static const successPale = Color(0xFFB6D3B2);
  static const darkSuccess = Color(0xFF83BB8B);

  // =========================================================
  // ESTADOS: ERROR
  // =========================================================

  static const error = Color(0xFFC74440);
  static const errorLight = Color(0xFFD87873);
  static const errorAccent = Color(0xFFE17D76);
  static const darkError = Color(0xFFFFA29B);

  // =========================================================
  // ESTADOS: ADVERTENCIA
  // =========================================================

  static const warning = Color(0xFFAD701D);
  static const warningLight = Color(0xFFD9A441);
  static const darkWarning = Color(0xFFE5BC70);

  // =========================================================
  // ESTADOS: INFORMACIÓN
  // =========================================================

  static const info = Color(0xFF477DA8);
  static const darkInfo = Color(0xFF8BB9DF);

  // =========================================================
  // AUTENTICACIÓN
  // =========================================================

  static const authHeading = Color(0xFF202923);
  static const darkAuthHeading = Color(0xFFE7ECE9);

  // =========================================================
  // RUTAS Y MAPAS
  // =========================================================

  static const routeGreen = Color(0xFF347653);
  static const routeGreenLight = Color(0xFF91BDA0);
  static const routePurple = Color(0xFF756783);
  static const routeMint = Color(0xFFB7D5C0);

  static const darkRouteGreen = Color(0xFF83B99A);
  static const darkRouteGreenLight = Color(0xFFAACDB5);
  static const darkRoutePurple = Color(0xFFB9A8CB);
  static const darkRouteMint = Color(0xFFB7D5C0);

  // =========================================================
  // TARJETAS BANCARIAS
  // =========================================================

  static const cardVisa = Color(0xFF285A91);
  static const cardVisaDark = Color(0xFF193D68);
  static const cardMastercard = Color(0xFFD39A36);
  static const cardMastercardLight = Color(0xFFE1B75D);

  // =========================================================
  // UBICACIÓN Y FUNCIONES ECOLÓGICAS
  // =========================================================

  static const location = info;
  static const ecoAccent = Color(0xFF779B52);

  // =========================================================
  // CARGA Y BARRAS DE NAVEGACIÓN
  // =========================================================

  static const loadingTrack = Color(0xFFDAE2DC);
  static const darkLoadingTrack = Color(0xFF35413A);

  static const topBarHighlight = Color(0xFFB9794C);
  static const topBarDeep = Color(0xFF273B32);

  // =========================================================
  // OVERLAYS
  // =========================================================

  static const overlayWhiteSubtle = Color(0x1EFFFFFF);
  static const overlayDarkSubtle = Color(0x1A000000);

  // =========================================================
  // BÚSQUEDA DE RUTAS
  // =========================================================

  static const routeSearchSurface = Color(0xFFF0F2F0);
  static const darkRouteSearchSurface = Color(0xFF222B32);

  // =========================================================
  // TERMINAL Y NAVEGACIÓN
  // =========================================================

  static const terminalPrimary = Color(0xFF52836A);
  static const terminalNavigationStart = Color(0xFF5789AE);
  static const terminalNavigationEnd = Color(0xFF639B6D);
  static const terminalNavigationSurface = Color(0xFFE4E8E5);

  static const darkTerminalNavigationSurface = Color(0xFF28332F);

  // =========================================================
  // TOPBAR / APPBAR
  // =========================================================
  static const topBarBackground = Color(0xFFB6D3B2);
  static const darkTopBarBackground = Color(0xFF1D252D);
}
