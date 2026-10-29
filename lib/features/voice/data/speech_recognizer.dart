import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Abstracción del reconocimiento de voz (permite probar sin micrófono).
abstract interface class SpeechRecognizer {
  /// `false` si no hay permiso de micrófono o el servicio no está disponible.
  Future<bool> initialize();

  Future<void> listen({
    required void Function(String words) onPartial,
    required void Function(String words) onFinal,
    required void Function() onDone,
    required void Function(String message) onError,
  });

  /// Termina de escuchar y entrega el resultado final.
  Future<void> stop();

  /// Termina de escuchar y descarta el resultado.
  Future<void> cancel();
}

class SpeechToTextRecognizer implements SpeechRecognizer {
  SpeechToTextRecognizer({this.preferredLocale = 'es_CO'});

  final String preferredLocale;
  final SpeechToText _speech = SpeechToText();

  Future<bool>? _initialization;
  String? _localeId;
  void Function(String message)? _onError;
  void Function()? _onDone;

  @override
  Future<bool> initialize() => _initialization ??= _doInitialize();

  Future<bool> _doInitialize() async {
    final available = await _speech.initialize(
      onError: (e) => _onError?.call(e.errorMsg),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onDone?.call();
        }
      },
    );
    if (available) _localeId = await _pickLocale();
    if (!available) _initialization = null; // permite reintentar
    return available;
  }

  /// es_CO si está instalado; si no, cualquier español; si no, el del sistema.
  Future<String?> _pickLocale() async {
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();

    final locales = await _speech.locales();
    final ids = {for (final l in locales) norm(l.localeId): l.localeId};

    return ids[norm(preferredLocale)] ??
        ids.entries.where((e) => e.key.startsWith('es')).firstOrNull?.value;
  }

  @override
  Future<void> listen({
    required void Function(String words) onPartial,
    required void Function(String words) onFinal,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    _onError = onError;
    _onDone = onDone;
    var delivered = false; // finalResult puede llegar más de una vez

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: _localeId,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
      ),
      onResult: (SpeechRecognitionResult result) {
        if (!result.finalResult) {
          onPartial(result.recognizedWords);
          return;
        }
        if (delivered) return;
        delivered = true;
        onFinal(result.recognizedWords);
      },
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}
