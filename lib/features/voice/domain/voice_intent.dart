/// Periodos que Gemini (o las reglas locales) pueden pedir.
enum SpendingPeriod {
  today('today'),
  yesterday('yesterday'),
  thisWeek('this_week'),
  lastWeek('last_week'),
  last7Days('last_7_days'),
  thisMonth('this_month'),
  lastMonth('last_month'),
  last30Days('last_30_days');

  const SpendingPeriod(this.wire);

  /// Nombre que usa Gemini en el JSON.
  final String wire;

  static SpendingPeriod? fromWire(String? value) {
    for (final period in values) {
      if (period.wire == value) return period;
    }
    return null;
  }
}

/// "¿Cuánto gasté la semana pasada?"
final class SpendingQueryIntent extends VoiceIntent {
  const SpendingQueryIntent(this.period, {required super.source});

  final SpendingPeriod period;

  @override
  String toString() => 'SpendingQueryIntent($period, $source)';
}

/// A dónde puede llevar un comando de voz dentro de busYA.
enum VoiceDestination { inicio, pagar, tarjetas, historial, rutas, perfil }

/// Quién resolvió la intención (útil para métricas y depuración).
enum IntentSource { local, gemini, none }

/// Resultado de interpretar lo que dijo el usuario.
sealed class VoiceIntent {
  const VoiceIntent({required this.source});

  final IntentSource source;
}

/// El usuario quiere ir a una pantalla / iniciar un flujo.
final class NavigateIntent extends VoiceIntent {
  const NavigateIntent(this.destination, {required super.source});

  final VoiceDestination destination;

  @override
  String toString() => 'NavigateIntent($destination, $source)';
}

/// Pregunta general: se responde con un texto corto, sin navegar.
final class AnswerIntent extends VoiceIntent {
  const AnswerIntent(this.message, {required super.source});

  final String message;

  @override
  String toString() => 'AnswerIntent($message, $source)';
}

/// Nada se pudo interpretar.
final class UnknownIntent extends VoiceIntent {
  const UnknownIntent({super.source = IntentSource.none});

  @override
  String toString() => 'UnknownIntent($source)';
}
