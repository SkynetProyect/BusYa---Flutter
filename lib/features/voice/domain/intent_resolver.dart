import 'voice_intent.dart';

/// Contrato de una estrategia para interpretar una frase.
///
/// Devuelve `null` cuando NO sabe resolverla, para que la siguiente estrategia
/// de la cadena (p. ej. Gemini) lo intente.
abstract interface class IntentResolver {
  Future<VoiceIntent?> resolve(String utterance);
}
