import 'application/voice_assistant.dart';
import 'application/voice_controller.dart';
import 'data/gemini_intent_resolver.dart';
import 'data/local_intent_resolver.dart';
import 'data/flutter_tts_speaker.dart';
import 'data/speech_recognizer.dart';
import 'data/local_spending_resolver.dart';

/// Punto único donde se ensamblan las piezas
/// La llave NO va en el código:
///   flutter run --dart-define-from-file=env.json
/// Sin llave la app sigue funcionando con las reglas locales.
///
VoiceController createVoiceController() {
  const geminiKey = String.fromEnvironment('GEMINI_API_KEY');

  return VoiceController(
    recognizer: SpeechToTextRecognizer(),
    speaker: FlutterTtsVoiceSpeaker(),
    assistant: VoiceAssistant(
      resolvers: [
        const LocalSpendingResolver(),

        const LocalIntentResolver(),
        if (geminiKey.isNotEmpty) GeminiIntentResolver(apiKey: geminiKey),
      ],
    ),
  );
}
