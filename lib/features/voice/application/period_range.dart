import '../domain/voice_intent.dart';

/// Rango [desde, hasta) en hora local del teléfono.
/// `frase` sirve para el mensaje hablado: "<Frase> gastaste ...".
typedef PeriodRange = ({
  DateTime desde,
  DateTime hasta,
  String titulo,
  String frase,
});

/// Semana = lunes a domingo. Colombia no tiene horario de verano.
PeriodRange rangeForPeriod(SpendingPeriod period, DateTime now) {
  DateTime dia(int offset) => DateTime(now.year, now.month, now.day + offset);

  final hoy = dia(0);
  final lunes = dia(DateTime.monday - now.weekday);

  return switch (period) {
    SpendingPeriod.today => (
      desde: hoy,
      hasta: dia(1),
      titulo: 'Hoy',
      frase: 'hoy',
    ),
    SpendingPeriod.yesterday => (
      desde: dia(-1),
      hasta: hoy,
      titulo: 'Ayer',
      frase: 'ayer',
    ),
    SpendingPeriod.thisWeek => (
      desde: lunes,
      hasta: DateTime(lunes.year, lunes.month, lunes.day + 7),
      titulo: 'Esta semana',
      frase: 'esta semana',
    ),
    SpendingPeriod.lastWeek => (
      desde: DateTime(lunes.year, lunes.month, lunes.day - 7),
      hasta: lunes,
      titulo: 'Semana pasada',
      frase: 'la semana pasada',
    ),
    SpendingPeriod.last7Days => (
      desde: dia(-6),
      hasta: dia(1),
      titulo: 'Últimos 7 días',
      frase: 'en los últimos 7 días',
    ),
    SpendingPeriod.thisMonth => (
      desde: DateTime(now.year, now.month),
      hasta: DateTime(now.year, now.month + 1),
      titulo: 'Este mes',
      frase: 'este mes',
    ),
    SpendingPeriod.lastMonth => (
      desde: DateTime(now.year, now.month - 1),
      hasta: DateTime(now.year, now.month),
      titulo: 'Mes pasado',
      frase: 'el mes pasado',
    ),
    SpendingPeriod.last30Days => (
      desde: dia(-29),
      hasta: dia(1),
      titulo: 'Últimos 30 días',
      frase: 'en los últimos 30 días',
    ),
  };
}
