import 'package:flutter_application_1/features/voice/application/period_range.dart';
import 'package:flutter_application_1/features/voice/data/local_spending_resolver.dart';
import 'package:flutter_application_1/features/voice/domain/voice_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalSpendingResolver', () {
    const resolver = LocalSpendingResolver();

    Future<SpendingPeriod?> periodOf(String text) async {
      final intent = await resolver.resolve(text);
      return intent is SpendingQueryIntent ? intent.period : null;
    }

    test('semana pasada', () async {
      expect(
        await periodOf('Quiero ver cuánto gasté la semana pasada en pasaje'),
        SpendingPeriod.lastWeek,
      );
    });

    test('este mes y ayer', () async {
      expect(
        await periodOf('cuánta plata llevo este mes'),
        SpendingPeriod.thisMonth,
      );
      expect(await periodOf('cuánto pagué ayer'), SpendingPeriod.yesterday);
    });

    test('sin periodo o sin palabra de gasto devuelve null', () async {
      expect(await resolver.resolve('cuánto he gastado'), isNull);
      expect(await resolver.resolve('ver mi historial'), isNull);
      expect(await resolver.resolve('hoy quiero pagar'), isNull);
    });
  });

  group('rangeForPeriod (jueves 29 oct 2026)', () {
    final now = DateTime(2026, 10, 29, 15, 30);

    test('semana pasada: lunes 19 a lunes 26', () {
      final r = rangeForPeriod(SpendingPeriod.lastWeek, now);
      expect(r.desde, DateTime(2026, 10, 19));
      expect(r.hasta, DateTime(2026, 10, 26));
    });

    test('esta semana: lunes 26 a lunes 2 nov', () {
      final r = rangeForPeriod(SpendingPeriod.thisWeek, now);
      expect(r.desde, DateTime(2026, 10, 26));
      expect(r.hasta, DateTime(2026, 11, 2));
    });

    test('este mes y mes pasado', () {
      final actual = rangeForPeriod(SpendingPeriod.thisMonth, now);
      expect(actual.desde, DateTime(2026, 10, 1));
      expect(actual.hasta, DateTime(2026, 11, 1));

      final pasado = rangeForPeriod(SpendingPeriod.lastMonth, now);
      expect(pasado.desde, DateTime(2026, 9, 1));
      expect(pasado.hasta, DateTime(2026, 10, 1));
    });

    test('mes pasado en enero cruza de año', () {
      final r = rangeForPeriod(SpendingPeriod.lastMonth, DateTime(2026, 1, 15));
      expect(r.desde, DateTime(2025, 12, 1));
      expect(r.hasta, DateTime(2026, 1, 1));
    });
  });
}
