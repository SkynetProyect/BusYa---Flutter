import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'voice_speaker.dart';

class FlutterTtsVoiceSpeaker implements VoiceSpeaker {
  FlutterTtsVoiceSpeaker({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts() {
    _flutterTts.setCompletionHandler(_completeSpeech);
    _flutterTts.setCancelHandler(_completeSpeech);
    _flutterTts.setErrorHandler(_handleSpeechError);
  }

  final FlutterTts _flutterTts;
  Future<void>? _initialization;
  Completer<void>? _speechCompletion;
  bool _isAvailable = true;

  @override
  bool get isAvailable => _isAvailable;

  Future<void> _initialize() => _initialization ??= _configure();

  Future<void> _configure() async {
    for (final language in ['es-CO', 'es-US', 'es-ES']) {
      if (await _flutterTts.isLanguageAvailable(language) == true) {
        await _flutterTts.setLanguage(language);
        return;
      }
    }
    throw StateError('No hay una voz española disponible en el dispositivo.');
  }

  @override
  Future<void> speak(String text) async {
    if (!_isAvailable) return;

    try {
      await _initialize();
      if (!_isAvailable) return;

      final completion = Completer<void>();
      _speechCompletion = completion;
      final result = await _flutterTts.speak(text);
      if (!_isAvailable) return;
      if (result != 1) {
        _markUnavailable('El motor TTS no aceptó el mensaje.');
        return;
      }

      await completion.future.timeout(const Duration(seconds: 30));
    } on Object catch (error) {
      _markUnavailable(error);
    } finally {
      _speechCompletion = null;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.stop();
    } on Object catch (error) {
      _markUnavailable(error);
    } finally {
      _completeSpeech();
    }
  }

  void _completeSpeech() {
    final completion = _speechCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  void _handleSpeechError(dynamic message) {
    _markUnavailable(message?.toString() ?? 'Error desconocido');
  }

  void _markUnavailable(Object error) {
    if (!_isAvailable) return;
    _isAvailable = false;
    debugPrint('Voice TTS no disponible: $error');
    _completeSpeech();
  }
}
