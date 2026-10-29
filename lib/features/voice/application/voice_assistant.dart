import 'package:flutter/foundation.dart';

import '../domain/intent_resolver.dart';
import '../domain/voice_intent.dart';

/// Recorre la cadena de resolvers en orden (local -> Gemini) y se queda con
/// la primera respuesta. Si uno falla (sin internet, timeout, cuota), pasa al
/// siguiente en lugar de romper el flujo.
class VoiceAssistant {
  VoiceAssistant({required List<IntentResolver> resolvers})
    : _resolvers = List.unmodifiable(resolvers);

  final List<IntentResolver> _resolvers;

  Future<VoiceIntent> interpret(String utterance) async {
    final text = utterance.trim();
    if (text.isEmpty) return const UnknownIntent();

    for (final resolver in _resolvers) {
      try {
        final intent = await resolver.resolve(text);
        if (intent != null) return intent;
      } catch (e) {
        debugPrint('${resolver.runtimeType} falló: $e');
      }
    }
    return const UnknownIntent();
  }
}
