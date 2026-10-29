import '../domain/intent_resolver.dart';
import '../domain/voice_intent.dart';
import 'text_normalizer.dart';

/// Resuelve sin internet frases como "cuánto gasté la semana pasada".
/// Necesita una palabra de gasto Y un periodo conocido; si falta alguno
/// devuelve null y la frase sigue su camino (navegación local o Gemini).
class LocalSpendingResolver implements IntentResolver {
  const LocalSpendingResolver();

  static const Set<String> _spendingWords = {
    'gaste',
    'gastado',
    'gasto',
    'gastos',
    'gastar',
    'pague',
    'pagado',
    'pagados',
    'plata',
  };

  // Las frases más específicas van primero.
  static final List<(String, SpendingPeriod)> _periods = [
    ('ultimos 7 dias', SpendingPeriod.last7Days),
    ('ultimos siete dias', SpendingPeriod.last7Days),
    ('ultima semana', SpendingPeriod.last7Days),
    ('ultimos 30 dias', SpendingPeriod.last30Days),
    ('ultimos treinta dias', SpendingPeriod.last30Days),
    ('ultimo mes', SpendingPeriod.last30Days),
    ('semana pasada', SpendingPeriod.lastWeek),
    ('mes pasado', SpendingPeriod.lastMonth),
    ('esta semana', SpendingPeriod.thisWeek),
    ('este mes', SpendingPeriod.thisMonth),
    ('ayer', SpendingPeriod.yesterday),
    ('hoy', SpendingPeriod.today),
  ];

  @override
  Future<VoiceIntent?> resolve(String utterance) async {
    final text = normalizeSpanish(utterance);
    final words = text.split(' ').toSet();
    if (!words.any(_spendingWords.contains)) return null;

    final padded = ' $text '; // para comparar frases completas
    for (final (phrase, period) in _periods) {
      if (padded.contains(' $phrase ')) {
        return SpendingQueryIntent(period, source: IntentSource.local);
      }
    }
    return null;
  }
}
