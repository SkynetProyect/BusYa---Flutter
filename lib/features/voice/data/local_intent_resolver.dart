import '../domain/intent_resolver.dart';
import '../domain/voice_intent.dart';
import 'text_normalizer.dart';

/// Capa A: reglas por palabras clave, sin red y sin latencia.
///
/// - Compara palabras COMPLETAS (no `contains`): "pagado" no dispara "pagar".
/// - Si la frase encaja con más de una pantalla es ambigua ("pagar con mi
///   tarjeta"), así que devuelve `null` y deja decidir a la siguiente capa.
class LocalIntentResolver implements IntentResolver {
  const LocalIntentResolver();

  static const Map<VoiceDestination, Set<String>> _keywords = {
    VoiceDestination.pagar: {
      'pagar',
      'pago',
      'pasaje',
      'nfc',
      'abordar',
      'escanear',
      'cobrar',
    },
    VoiceDestination.historial: {
      'historial',
      'movimientos',
      'transacciones',
      'viajes',
      'gastos',
      'gastado',
      'gaste',
      'pagado',
      'pagados',
    },
    VoiceDestination.tarjetas: {
      'tarjeta',
      'tarjetas',
      'bancaria',
      'bancarias',
      'saldo',
    },
    VoiceDestination.inicio: {'inicio', 'mapa'},
    VoiceDestination.rutas: {'ruta', 'rutas', 'recorrido', 'recorridos'},
    VoiceDestination.perfil: {'perfil', 'cuenta'},
  };

  @override
  Future<VoiceIntent?> resolve(String utterance) async {
    final words = normalizeSpanish(utterance).split(' ').toSet();

    final matches = _keywords.entries
        .where((entry) => entry.value.any(words.contains))
        .map((entry) => entry.key)
        .toList();

    if (matches.length != 1) return null;
    return NavigateIntent(matches.single, source: IntentSource.local);
  }
}
