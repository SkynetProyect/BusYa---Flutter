class GastoDia {
  const GastoDia({required this.dia, required this.total});

  final DateTime dia;
  final num total;
}

class ResumenGasto {
  const ResumenGasto({
    required this.total,
    required this.viajes,
    required this.porDia,
  });

  final num total;
  final int viajes;
  final List<GastoDia> porDia;

  num get promedio => viajes == 0 ? 0 : total / viajes;

  factory ResumenGasto.fromJson(Map<String, dynamic> json) {
    final dias = json['por_dia'];
    return ResumenGasto(
      total: _aNum(json['total']),
      viajes: _aNum(json['viajes']).toInt(),
      porDia: dias is List
          ? [
              for (final item in dias)
                if (item is Map)
                  GastoDia(
                    dia: DateTime.parse('${item['dia']}'),
                    total: _aNum(item['total']),
                  ),
            ]
          : const [],
    );
  }

  /// Texto para decir en voz alta. [frase] viene de `rangeForPeriod`.
  String textoHablado(String frase) {
    final inicio = frase[0].toUpperCase() + frase.substring(1);
    if (viajes == 0) return '$inicio no registraste viajes.';
    final cantidad = viajes == 1 ? '1 viaje' : '$viajes viajes';
    return '$inicio gastaste ${total.round()} pesos en $cantidad.';
  }
}

num _aNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;
