import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/voice/application/voice_assistant.dart';
import 'package:flutter_application_1/features/voice/application/voice_controller.dart';
import 'package:flutter_application_1/features/voice/data/speech_recognizer.dart';
import 'package:flutter_application_1/features/voice/data/voice_speaker.dart';
import 'package:flutter_application_1/features/voice/domain/intent_resolver.dart';
import 'package:flutter_application_1/features/voice/domain/voice_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRecognizer implements SpeechRecognizer {
  void Function(String)? onPartial;
  void Function(String)? onFinal;
  void Function()? onDone;
  void Function(String)? onError;
  int stopCalls = 0;
  int cancelCalls = 0;
  Completer<void>? stopCompleter;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listen({
    required void Function(String words) onPartial,
    required void Function(String words) onFinal,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    this.onPartial = onPartial;
    this.onFinal = onFinal;
    this.onDone = onDone;
    this.onError = onError;
  }

  @override
  Future<void> stop() {
    stopCalls++;
    return stopCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

class _FakeSpeaker implements VoiceSpeaker {
  final spoken = <String>[];
  int stopCalls = 0;
  bool throwOnSpeak = false;
  bool _isAvailable = true;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<void> speak(String text) async {
    if (throwOnSpeak) {
      _isAvailable = false;
      throw StateError('TTS no disponible');
    }
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRecognizer recognizer;
  late _FakeSpeaker speaker;
  late VoiceController controller;
  var hapticCalls = 0;

  VoiceController createController({Duration? stopTimeout}) {
    recognizer = _FakeRecognizer();
    speaker = _FakeSpeaker();
    hapticCalls = 0;
    controller = VoiceController(
      recognizer: recognizer,
      assistant: VoiceAssistant(resolvers: const []),
      speaker: speaker,
      stopTimeout: stopTimeout ?? VoiceController.defaultStopTimeout,
      selectionClick: () async => hapticCalls++,
    );
    return controller;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    createController();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> beginListening() async {
    await controller.startListening();
    expect(controller.status, VoiceStatus.listening);
  }

  test('stop changes to processing before recognizer stop completes', () async {
    recognizer.stopCompleter = Completer<void>();
    await beginListening();

    unawaited(controller.stopListening());

    expect(controller.status, VoiceStatus.thinking);
    expect(recognizer.stopCalls, 1);
    recognizer.stopCompleter!.complete();
  });

  test('cancel discards transcription without emitting an intent', () async {
    var emitted = false;
    final subscription = controller.intents.listen((_) => emitted = true);
    await beginListening();
    recognizer.onPartial!('historial');

    await controller.cancel();
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, VoiceStatus.idle);
    expect(controller.transcript, isEmpty);
    expect(emitted, isFalse);
    expect(recognizer.cancelCalls, 1);
    expect(speaker.spoken, ['¿Qué necesitas hoy?']);
    await subscription.cancel();
  });

  test('stop timeout processes the last partial transcript', () async {
    controller.dispose();
    createController(stopTimeout: const Duration(milliseconds: 20));
    final intentFuture = controller.intents.first;
    await beginListening();
    recognizer.onPartial!('historial');
    await controller.stopListening();

    expect(await intentFuture, isA<UnknownIntent>());
    expect(controller.transcript, isEmpty);
    expect(controller.actionMessage, 'No te entendí');
    expect(controller.stopTimeout, const Duration(milliseconds: 20));
  });

  test('final result clears transcript and shows a temporary action', () async {
    controller.dispose();
    final testController = VoiceController(
      recognizer: recognizer,
      assistant: VoiceAssistant(
        resolvers: [
          _FixedResolver(
            const NavigateIntent(
              VoiceDestination.historial,
              source: IntentSource.local,
            ),
          ),
        ],
      ),
      speaker: speaker,
      selectionClick: () async {},
    );
    controller = testController;
    final intentFuture = controller.intents.first;
    await beginListening();
    recognizer.onPartial!('ver mi historial');
    recognizer.onFinal!('ver mi historial');

    expect(await intentFuture, isA<NavigateIntent>());
    expect(controller.transcript, isEmpty);
    expect(controller.actionMessage, 'Abriendo historial');
    expect(speaker.spoken, ['¿Qué necesitas hoy?', 'Abriendo historial']);
  });

  test('greets once per controller session', () async {
    await beginListening();
    await controller.cancel();
    await beginListening();

    expect(
      speaker.spoken.where((text) => text == '¿Qué necesitas hoy?'),
      hasLength(1),
    );
    expect(hapticCalls, greaterThan(0));
  });

  test('mute preference is persisted and prevents speech', () async {
    await controller.toggleMuted();
    expect(controller.isMuted, isTrue);

    controller.dispose();
    recognizer = _FakeRecognizer();
    speaker = _FakeSpeaker();
    controller = VoiceController(
      recognizer: recognizer,
      assistant: VoiceAssistant(resolvers: const []),
      speaker: speaker,
      selectionClick: () async {},
    );

    await controller.initialize();
    expect(controller.isMuted, isTrue);
    await beginListening();
    expect(speaker.spoken, isEmpty);
  });

  test(
    'submitText processes a phrase without opening the microphone',
    () async {
      final resolver = _RecordingResolver(
        const NavigateIntent(
          VoiceDestination.historial,
          source: IntentSource.local,
        ),
      );
      controller.dispose();
      recognizer = _FakeRecognizer();
      speaker = _FakeSpeaker();
      controller = VoiceController(
        recognizer: recognizer,
        assistant: VoiceAssistant(resolvers: [resolver]),
        speaker: speaker,
        selectionClick: () async {},
      );
      final intentFuture = controller.intents.first;

      await controller.submitText('Ver historial');

      expect(await intentFuture, isA<NavigateIntent>());
      expect(resolver.utterance, 'Ver historial');
      expect(recognizer.onPartial, isNull);
      expect(controller.transcript, isEmpty);
      expect(controller.actionMessage, 'Abriendo historial');
    },
  );

  test('a TTS failure does not interrupt intent processing', () async {
    controller.dispose();
    recognizer = _FakeRecognizer();
    speaker = _FakeSpeaker()..throwOnSpeak = true;
    controller = VoiceController(
      recognizer: recognizer,
      assistant: VoiceAssistant(
        resolvers: [
          _RecordingResolver(
            const NavigateIntent(
              VoiceDestination.rutas,
              source: IntentSource.local,
            ),
          ),
        ],
      ),
      speaker: speaker,
      selectionClick: () async {},
    );
    final intentFuture = controller.intents.first;

    await controller.submitText('Ver rutas');

    expect(
      (await intentFuture as NavigateIntent).destination,
      VoiceDestination.rutas,
    );
    expect(controller.status, VoiceStatus.idle);
    expect(controller.actionMessage, 'Abriendo rutas');
    expect(controller.errorMessage, isNull);
    expect(controller.isVoiceAvailable, isFalse);
  });

  test('default stop timeout is two seconds', () {
    expect(VoiceController.defaultStopTimeout, const Duration(seconds: 2));
  });
}

class _FixedResolver implements IntentResolver {
  const _FixedResolver(this.intent);

  final VoiceIntent intent;

  @override
  Future<VoiceIntent?> resolve(String utterance) async => intent;
}

class _RecordingResolver implements IntentResolver {
  _RecordingResolver(this.intent);

  final VoiceIntent intent;
  String? utterance;

  @override
  Future<VoiceIntent?> resolve(String utterance) async {
    this.utterance = utterance;
    return intent;
  }
}
