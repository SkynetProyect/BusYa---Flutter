import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/voice/application/voice_assistant.dart';
import 'package:flutter_application_1/features/voice/data/local_intent_resolver.dart';
import 'package:flutter_application_1/features/voice/domain/intent_resolver.dart';
import 'package:flutter_application_1/features/voice/domain/voice_intent.dart';

class _FakeResolver implements IntentResolver {
  _FakeResolver(this._result);
  final VoiceIntent? _result;
  int calls = 0;

  @override
  Future<VoiceIntent?> resolve(String utterance) async {
    calls++;
    return _result;
  }
}

class _ThrowingResolver implements IntentResolver {
  @override
  Future<VoiceIntent?> resolve(String utterance) =>
      throw Exception('sin internet');
}

void main() {
  group('LocalIntentResolver', () {
    const resolver = LocalIntentResolver();

    Future<VoiceDestination?> destinationOf(String text) async {
      final intent = await resolver.resolve(text);
      return intent is NavigateIntent ? intent.destination : null;
    }

    test('reconoce comandos directos', () async {
      expect(
        await destinationOf('Quiero pagar el pasaje'),
        VoiceDestination.pagar,
      );
      expect(
        await destinationOf('quiero pagar el bus'),
        VoiceDestination.pagar,
      );
      expect(await destinationOf('ver las rutas'), VoiceDestination.rutas);
      expect(
        await destinationOf('Ver mi historial'),
        VoiceDestination.historial,
      );
      expect(await destinationOf('Mis tarjetas'), VoiceDestination.tarjetas);
    });

    test('ignora tildes y mayúsculas', () async {
      expect(
        await destinationOf('¿Cuánto he GASTADO?'),
        VoiceDestination.historial,
      );
    });

    test('"pagado" no se confunde con "pagar"', () async {
      expect(
        await destinationOf('mis viajes pagados'),
        VoiceDestination.historial,
      );
    });

    test('frase ambigua o desconocida devuelve null', () async {
      expect(await resolver.resolve('pagar con mi tarjeta'), isNull);
      expect(await resolver.resolve('qué hora es'), isNull);
    });
  });

  group('VoiceAssistant', () {
    test('si el local resuelve, no llama a Gemini', () async {
      final gemini = _FakeResolver(const UnknownIntent());
      final assistant = VoiceAssistant(
        resolvers: [const LocalIntentResolver(), gemini],
      );

      final intent = await assistant.interpret('historial');

      expect(intent, isA<NavigateIntent>());
      expect(gemini.calls, 0);
    });

    test('si el local no resuelve, usa Gemini', () async {
      final assistant = VoiceAssistant(
        resolvers: [
          const LocalIntentResolver(),
          _FakeResolver(
            const NavigateIntent(
              VoiceDestination.historial,
              source: IntentSource.gemini,
            ),
          ),
        ],
      );

      final intent = await assistant.interpret('parce, cuánto llevo este mes');

      expect((intent as NavigateIntent).source, IntentSource.gemini);
    });

    test('si Gemini falla, devuelve UnknownIntent sin lanzar', () async {
      final assistant = VoiceAssistant(
        resolvers: [const LocalIntentResolver(), _ThrowingResolver()],
      );

      expect(await assistant.interpret('blablabla'), isA<UnknownIntent>());
    });

    test('texto vacío es UnknownIntent', () async {
      final assistant = VoiceAssistant(resolvers: const []);
      expect(await assistant.interpret('   '), isA<UnknownIntent>());
    });
  });
}
