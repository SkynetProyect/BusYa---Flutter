import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_application_1/features/voice/data/flutter_tts_speaker.dart';

class _FakeFlutterTts extends FlutterTts {
  _FakeFlutterTts({this.failLanguageLookup = false});

  final bool failLanguageLookup;
  final availableLanguages = <String>[];
  final selectedLanguages = <String>[];
  final spoken = <String>[];

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async {
    throw MissingPluginException('awaitSpeakCompletion is unsupported');
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    if (failLanguageLookup) {
      throw MissingPluginException('TTS plugin unavailable');
    }
    return availableLanguages.contains(language);
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    selectedLanguages.add(language);
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    completionHandler?.call();
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'waits for the completion callback and never configures await completion',
    () async {
      final flutterTts = _FakeFlutterTts()..availableLanguages.add('es-US');
      final speaker = FlutterTtsVoiceSpeaker(flutterTts: flutterTts);

      await speaker.speak('Hola');

      expect(flutterTts.selectedLanguages, ['es-US']);
      expect(flutterTts.spoken, ['Hola']);
      expect(speaker.isAvailable, isTrue);
    },
  );

  test('a missing TTS plugin is captured and disables speech', () async {
    final speaker = FlutterTtsVoiceSpeaker(
      flutterTts: _FakeFlutterTts(failLanguageLookup: true),
    );

    await expectLater(speaker.speak('Hola'), completes);

    expect(speaker.isAvailable, isFalse);
  });
}
