import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Puntos necesarios para ganar un pasaje gratis.
const int kMetaPuntosEco = 30;

class PuntosEstado {
  final int puntos;
  final int pasajesGratis;

  const PuntosEstado({this.puntos = 0, this.pasajesGratis = 0});

  double get progreso => (puntos / kMetaPuntosEco).clamp(0.0, 1.0);
  int get faltan => (kMetaPuntosEco - puntos).clamp(0, kMetaPuntosEco);
}

class ResultadoPunto {
  final PuntosEstado estado;
  final bool pasajeGanado;

  const ResultadoPunto(this.estado, {required this.pasajeGanado});
}

/// Singleton: `PuntosService()` siempre devuelve la misma instancia, así el
/// top bar y la pantalla de puntos comparten el mismo [estado].
class PuntosService {
  PuntosService._();
  static final PuntosService _instancia = PuntosService._();
  factory PuntosService() => _instancia;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Escúchalo con ValueListenableBuilder para actualizar la UI sola.
  final ValueNotifier<PuntosEstado> estado = ValueNotifier(
    const PuntosEstado(),
  );

  Future<PuntosEstado> obtenerEstado() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      estado.value = const PuntosEstado();
      return estado.value;
    }

    final data = await _supabase
        .from('usuarios')
        .select('puntos_eco, pasajes_eco_gratis')
        .eq('id', user.id)
        .maybeSingle();

    estado.value = PuntosEstado(
      puntos: (data?['puntos_eco'] as int?) ?? 0,
      pasajesGratis: (data?['pasajes_eco_gratis'] as int?) ?? 0,
    );
    return estado.value;
  }

  Future<int> obtenerPuntos() async => (await obtenerEstado()).puntos;

  /// Suma 1 punto. Al llegar a 30 el servidor reinicia el contador y
  /// acredita un pasaje gratis. Nunca debe bloquear el pago: si falla,
  /// devuelve null.
  Future<ResultadoPunto?> sumarPuntoPorViaje() async {
    if (_supabase.auth.currentUser == null) return null;

    try {
      final r = await _supabase.rpc('sumar_punto_eco');
      if (r is! Map) return null;

      final nuevo = PuntosEstado(
        puntos: r['puntos'] as int,
        pasajesGratis: r['pasajes_gratis'] as int,
      );
      estado.value = nuevo;
      return ResultadoPunto(nuevo, pasajeGanado: r['pasaje_ganado'] == true);
    } catch (_) {
      return null;
    }
  }

  /// Llamar al cerrar sesión (por ejemplo en el listener de auth).
  void limpiar() => estado.value = const PuntosEstado();
}
