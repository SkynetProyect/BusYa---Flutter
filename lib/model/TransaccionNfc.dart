class TransaccionNfc {
  final String? id;
  final String? idUsuario;
  final int? idBus;
  final int? idTarjeta;
  final double monto;
  final DateTime? fechaTransaccion;
  final bool? sincronizadoOffline;
  final double? latitud;
  final double? longitud;
  final bool esEmergencia;
  final String? nombreRuta;
  final String? marcaTarjeta;
  final String? ultimosCuatro;

  TransaccionNfc({
    this.id,
    this.idUsuario,
    this.idBus,
    this.idTarjeta,
    required this.monto,
    this.fechaTransaccion,
    this.sincronizadoOffline,
    this.latitud,
    this.longitud,
    this.esEmergencia = false,
    this.nombreRuta,
    this.marcaTarjeta,
    this.ultimosCuatro,
  });

  /// Ej: "Visa •••• 4242", o null si no hay tarjeta (pasaje de emergencia, tarjeta eliminada)
  String? get tarjetaLabel {
    if (marcaTarjeta == null || ultimosCuatro == null) return null;
    return '$marcaTarjeta •••• $ultimosCuatro';
  }

  factory TransaccionNfc.fromRow(Map<String, dynamic> row) {
    final rutaNombre = row['buses']?['rutas']?['nombre'] as String?;
    final tarjeta = row['tarjetas'] as Map<String, dynamic>?;

    return TransaccionNfc(
      id: row['id'] as String?,
      idUsuario: row['id_usuario'] as String?,
      idBus: row['id_bus'] as int?,
      idTarjeta: row['id_tarjeta'] as int?,
      monto: (row['monto'] as num).toDouble(),
      fechaTransaccion: row['fecha_transaccion'] != null
          ? DateTime.parse(row['fecha_transaccion'] as String)
          : null,
      sincronizadoOffline: row['sincronizado_offline'] as bool?,
      latitud: row['latitud'] != null
          ? (row['latitud'] as num).toDouble()
          : null,
      longitud: row['longitud'] != null
          ? (row['longitud'] as num).toDouble()
          : null,
      esEmergencia: row['es_emergencia'] as bool? ?? false,
      nombreRuta: rutaNombre,
      marcaTarjeta: tarjeta?['marca'] as String?,
      ultimosCuatro: tarjeta?['ultimos_cuatro_digitos'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
    if (id != null) 'id': id,
    'id_usuario': idUsuario,
    'id_bus': idBus,
    'id_tarjeta': idTarjeta,
    'monto': monto,
    'sincronizado_offline': sincronizadoOffline,
    'latitud': latitud,
    'longitud': longitud,
    'es_emergencia': esEmergencia,
  };
}
