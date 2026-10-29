import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;

/// Puente entre la pantalla Rutas y el mapa (Inicio).
/// Rutas deja aquí la ruta pedida; Inicio la consume y la selecciona.
class MapaRutaRequest {
  MapaRutaRequest._();

  /// Ruta pendiente de abrir en el mapa (null = nada pendiente).
  static final ValueNotifier<Ruta?> pending = ValueNotifier<Ruta?>(null);

  /// Lo registra el shell de navegación para cambiar a la pestaña del mapa.
  static VoidCallback? irAlMapa;

  static void abrir(Ruta ruta) {
    pending.value = ruta;
    irAlMapa?.call();
  }
}
