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
  final bool emergenciaPagada;
  final DateTime? fechaPagoEmergencia;
  final int? idTarjetaPagoEmergencia;
  final String? nombreRuta;
  final String? marcaTarjeta;
  final String? ultimosCuatro;
  final String? marcaTarjetaPago;
  final String? ultimosCuatroPago;

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
    this.emergenciaPagada = false,
    this.fechaPagoEmergencia,
    this.idTarjetaPagoEmergencia,
    this.nombreRuta,
    this.marcaTarjeta,
    this.ultimosCuatro,
    this.marcaTarjetaPago,
    this.ultimosCuatroPago,
  });

  /// Tarjeta del cobro. Ej: "Visa •••• 4242"
  String? get tarjetaLabel {
    if (marcaTarjeta == null || ultimosCuatro == null) return null;
    return '$marcaTarjeta •••• $ultimosCuatro';
  }

  /// Tarjeta con la que se saldó el pasaje de emergencia
  String? get tarjetaPagoLabel {
    if (marcaTarjetaPago == null || ultimosCuatroPago == null) return null;
    return '$marcaTarjetaPago •••• $ultimosCuatroPago';
  }

  static DateTime? _fecha(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory TransaccionNfc.fromRow(Map<String, dynamic> row) {
    final rutaNombre = row['buses']?['rutas']?['nombre'] as String?;
    final tarjeta = row['tarjetas'] as Map<String, dynamic>?;
    final tarjetaPago = row['tarjeta_pago'] as Map<String, dynamic>?;

    return TransaccionNfc(
      id: row['id'] as String?,
      idUsuario: row['id_usuario'] as String?,
      idBus: row['id_bus'] as int?,
      idTarjeta: row['id_tarjeta'] as int?,
      monto: (row['monto'] as num).toDouble(),
      fechaTransaccion: _fecha(row['fecha_transaccion']),
      sincronizadoOffline: row['sincronizado_offline'] as bool?,
      latitud: row['latitud'] != null
          ? (row['latitud'] as num).toDouble()
          : null,
      longitud: row['longitud'] != null
          ? (row['longitud'] as num).toDouble()
          : null,
      esEmergencia: row['es_emergencia'] as bool? ?? false,
      emergenciaPagada: row['emergencia_pagada'] as bool? ?? false,
      fechaPagoEmergencia: _fecha(row['fecha_pago_emergencia']),
      idTarjetaPagoEmergencia: row['id_tarjeta_pago_emergencia'] as int?,
      nombreRuta: rutaNombre,
      marcaTarjeta: tarjeta?['marca'] as String?,
      ultimosCuatro: tarjeta?['ultimos_cuatro_digitos'] as String?,
      marcaTarjetaPago: tarjetaPago?['marca'] as String?,
      ultimosCuatroPago: tarjetaPago?['ultimos_cuatro_digitos'] as String?,
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
