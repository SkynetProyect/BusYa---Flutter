import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/speech_recognizer.dart';
import '../data/voice_speaker.dart';
import '../domain/voice_intent.dart';
import 'voice_assistant.dart';

enum VoiceStatus { idle, listening, thinking, speaking }

class VoiceController extends ChangeNotifier {
  VoiceController({
    required SpeechRecognizer recognizer,
    required VoiceAssistant assistant,
    required VoiceSpeaker speaker,
    this.stopTimeout = defaultStopTimeout,
    Future<void> Function()? selectionClick,
  }) : _recognizer = recognizer,
       _assistant = assistant,
       _speaker = speaker,
       _selectionClick = selectionClick ?? HapticFeedback.selectionClick;

  static const _mutedPreferenceKey = 'voice_assistant_muted';
  static const _greeting = '¿Qué necesitas hoy?';
  static const defaultStopTimeout = Duration(seconds: 2);
  static const actionMessageDuration = Duration(milliseconds: 1500);

  final SpeechRecognizer _recognizer;
  final VoiceAssistant _assistant;
  final VoiceSpeaker _speaker;
  final Future<void> Function() _selectionClick;
  final Duration stopTimeout;
  final _intents = StreamController<VoiceIntent>.broadcast();

  VoiceStatus _status = VoiceStatus.idle;
  String _transcript = '';
  String? _actionMessage;
  String? _errorMessage;
  bool _disposed = false;
  bool _stopRequested = false;
  bool _finalHandled = false;
  bool _greeted = false;
  bool _isMuted = false;
  Timer? _stopTimer;
  Timer? _actionTimer;
  Future<void>? _initialization;
  int _operation = 0;

  VoiceStatus get status => _status;
  String get transcript => _transcript;
  String? get actionMessage => _actionMessage;
  String? get errorMessage => _errorMessage;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isMuted => _isMuted;
  bool get isPanelVisible =>
      _status != VoiceStatus.idle ||
      _actionMessage != null ||
      _errorMessage != null;
  bool get isVoiceAvailable => _speaker.isAvailable;
  Stream<VoiceIntent> get intents => _intents.stream;

  void buttonTapped() => _provideHaptic();

  Future<void> initialize() => _initialization ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_disposed) return;
      _isMuted = preferences.getBool(_mutedPreferenceKey) ?? false;
      _notify();
    } on Object catch (error) {
      _showError('No se pudo cargar el silencio de voz: $error');
    }
  }

  Future<void> toggleMuted() async {
    await initialize();
    if (_disposed) return;

    final previousValue = _isMuted;
    _isMuted = !_isMuted;
    _notify();

    if (_isMuted && _status == VoiceStatus.speaking) {
      final operation = ++_operation;
      _setStatus(VoiceStatus.thinking);
      try {
        await _speaker.stop();
      } on Object catch (error) {
        debugPrint('No se pudo detener el TTS: $error');
      }
      if (!_isCurrent(operation)) return;
      _setStatus(VoiceStatus.idle);
    }

    try {
      final saved = await (await SharedPreferences.getInstance()).setBool(
        _mutedPreferenceKey,
        _isMuted,
      );
      if (!saved) throw StateError('No se pudo guardar la preferencia.');
    } on Object catch (error) {
      _isMuted = previousValue;
      _showError('No se pudo guardar el silencio de voz: $error');
    }
  }

  Future<void> startListening() async {
    if (_disposed || _status != VoiceStatus.idle) return;
    await initialize();
    if (_disposed || _status != VoiceStatus.idle) return;

    final operation = ++_operation;
    _stopRequested = false;
    _finalHandled = false;
    _transcript = '';
    _actionMessage = null;
    _actionTimer?.cancel();
    _errorMessage = null;
    _notify();

    if (!_greeted) {
      _greeted = true;
      if (!_isMuted) {
        _setStatus(VoiceStatus.speaking);
        if (!await _speak(_greeting) || !_isCurrent(operation)) return;
      }
    } else {
      _provideHaptic();
      if (!_isCurrent(operation)) return;
    }

    await _beginRecognition(operation);
  }

  Future<void> submitText(String text) async {
    final words = text.trim();
    if (_disposed || words.isEmpty) return;
    await initialize();
    if (_disposed) return;

    final previousStatus = _status;
    final operation = ++_operation;
    _stopTimer?.cancel();
    _actionTimer?.cancel();
    _stopRequested = false;
    _finalHandled = false;
    _actionMessage = null;
    _errorMessage = null;

    if (previousStatus == VoiceStatus.speaking) {
      await _stopSpeaker();
    } else if (previousStatus == VoiceStatus.listening ||
        previousStatus == VoiceStatus.thinking) {
      try {
        await _recognizer.cancel();
      } on Object catch (error) {
        debugPrint('No se pudo cerrar el micrófono antes del texto: $error');
      }
    }
    if (!_isCurrent(operation)) return;

    _transcript = words;
    _setStatus(VoiceStatus.thinking);
    await _processWords(words, operation);
  }

  Future<void> interruptSpeechAndListen() async {
    if (_disposed || _status != VoiceStatus.speaking) return;
    final operation = ++_operation;
    _stopRequested = false;
    _setStatus(VoiceStatus.thinking);
    await _stopSpeaker();
    if (!_isCurrent(operation)) return;
    await _beginRecognition(operation);
  }

  Future<void> _stopSpeaker() async {
    try {
      await _speaker.stop();
    } on Object catch (error) {
      debugPrint('No se pudo detener el TTS: $error');
    }
  }

  Future<void> _beginRecognition(int operation) async {
    if (!_isCurrent(operation)) return;
    _setStatus(VoiceStatus.thinking);

    try {
      final available = await _recognizer.initialize();
      if (!_isCurrent(operation)) return;
      if (!available) {
        _fail('El micrófono no está disponible. Revisa los permisos.');
        return;
      }

      _setStatus(VoiceStatus.listening);
      await _recognizer.listen(
        onPartial: (words) {
          if (!_isCurrent(operation) ||
              (_status != VoiceStatus.listening && !_stopRequested)) {
            return;
          }
          _transcript = words;
          _notify();
        },
        onFinal: (words) => _onFinalWords(words, operation),
        onDone: () => _onRecognizerDone(operation),
        onError: (message) {
          if (_isCurrent(operation)) _fail(message);
        },
      );
    } on Object catch (error) {
      if (_isCurrent(operation)) _fail('Error al escuchar: $error');
    }
  }

  Future<void> stopListening() async {
    if (_disposed || _status != VoiceStatus.listening) return;

    final operation = _operation;
    _stopRequested = true;
    _setStatus(VoiceStatus.thinking);
    _stopTimer?.cancel();
    _stopTimer = Timer(stopTimeout, () => _finishWithPartial(operation));

    try {
      await _recognizer.stop();
    } on Object catch (error) {
      if (_isCurrent(operation)) _fail('No se pudo detener la escucha: $error');
    }
  }

  Future<void> cancel() async {
    if (_disposed) return;
    ++_operation;
    _stopRequested = false;
    _finalHandled = true;
    _stopTimer?.cancel();
    _actionTimer?.cancel();
    _transcript = '';
    _actionMessage = null;
    _errorMessage = null;
    _setStatus(VoiceStatus.idle);

    try {
      await _recognizer.cancel();
    } on Object catch (error) {
      _showError('No se pudo cancelar la escucha: $error');
    }
    await _stopSpeaker();
  }

  Future<void> dismissPanel() async {
    if (_disposed) return;
    if (_status != VoiceStatus.idle) {
      await cancel();
      return;
    }
    _actionTimer?.cancel();
    _actionMessage = null;
    _errorMessage = null;
    _transcript = '';
    _notify();
  }

  void _onRecognizerDone(int operation) {
    if (!_isCurrent(operation) || _finalHandled) return;
    if (_status == VoiceStatus.listening || _stopRequested) {
      _finishWithPartial(operation);
    }
  }

  void _finishWithPartial(int operation) {
    if (!_isCurrent(operation) || _finalHandled) return;
    _stopTimer?.cancel();

    final words = _transcript.trim();
    if (words.isEmpty) {
      _stopRequested = false;
      _transcript = '';
      _setStatus(VoiceStatus.idle);
      return;
    }
    _onFinalWords(words, operation);
  }

  Future<void> _onFinalWords(String words, int operation) async {
    if (!_isCurrent(operation) ||
        _finalHandled ||
        (_status != VoiceStatus.listening && !_stopRequested)) {
      return;
    }

    _finalHandled = true;
    _stopRequested = false;
    _stopTimer?.cancel();
    final finalWords = words.trim();
    _transcript = '';

    if (finalWords.isEmpty) {
      _setStatus(VoiceStatus.idle);
      return;
    }

    await _processWords(finalWords, operation);
  }

  Future<void> _processWords(String words, int operation) async {
    _transcript = '';
    _setStatus(VoiceStatus.thinking);
    try {
      final intent = await _assistant.interpret(words);
      if (!_isCurrent(operation)) return;

      _actionMessage = _actionFor(intent);
      _actionTimer?.cancel();
      _actionTimer = Timer(actionMessageDuration, () {
        _actionMessage = null;
        _notify();
      });
      _intents.add(intent);

      final response = _spokenResponse(intent);
      if (!_isMuted && response != null) {
        _setStatus(VoiceStatus.speaking);
        await _speak(response);
      }
      if (_isCurrent(operation)) _setStatus(VoiceStatus.idle);
    } on Object catch (error) {
      if (_isCurrent(operation)) _fail('No se pudo procesar la voz: $error');
    }
  }

  Future<bool> _speak(String text) async {
    if (_isMuted || _disposed) return false;
    try {
      await _speaker.speak(text);
      return !_disposed;
    } on Object catch (error) {
      debugPrint('Voice TTS no disponible: $error');
      return !_disposed;
    }
  }

  String _actionFor(VoiceIntent intent) => switch (intent) {
    NavigateIntent(destination: final destination) =>
      'Abriendo ${_destinationName(destination)}',
    SpendingQueryIntent() => 'Abriendo historial',
    AnswerIntent() => 'Respuesta lista',
    UnknownIntent() => 'No te entendí',
  };

  String? _spokenResponse(VoiceIntent intent) => switch (intent) {
    NavigateIntent(destination: final destination) =>
      'Abriendo ${_destinationName(destination)}',
    SpendingQueryIntent() => 'Abriendo historial',
    AnswerIntent(message: final message) => message,
    UnknownIntent() => 'No te entendí, intenta de nuevo',
  };

  String _destinationName(VoiceDestination destination) =>
      switch (destination) {
        VoiceDestination.inicio => 'inicio',
        VoiceDestination.pagar => 'pagos',
        VoiceDestination.tarjetas => 'tarjetas',
        VoiceDestination.historial => 'historial',
        VoiceDestination.rutas => 'rutas',
        VoiceDestination.perfil => 'perfil',
      };

  void _fail(String message) {
    if (_disposed) return;
    _stopTimer?.cancel();
    _stopRequested = false;
    _errorMessage = message;
    _setStatus(VoiceStatus.idle);
  }

  void _showError(String message) {
    if (_disposed) return;
    _errorMessage = message;
    _notify();
  }

  bool _isCurrent(int operation) => !_disposed && operation == _operation;

  void _setStatus(VoiceStatus status) {
    if (_status == status) return;
    _status = status;
    _notify();
    _provideHaptic();
  }

  void _provideHaptic() {
    unawaited(
      _selectionClick().catchError((Object error) {
        debugPrint('No se pudo reproducir la vibración: $error');
      }),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer?.cancel();
    _actionTimer?.cancel();
    unawaited(_recognizer.cancel());
    unawaited(_stopSpeaker());
    _intents.close();
    super.dispose();
  }
}
