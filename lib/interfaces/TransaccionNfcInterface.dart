abstract class TransaccionNfcInterface {
  final String? id;
  final String? idBilletera;
  final int? idBus;
  final double monto;
  final DateTime? fechaTransaccion;
  final bool? sincronizadoOffline;
  final double? latitud;
  final double? longitud;

  TransaccionNfcInterface({
    this.id,
    this.idBilletera,
    this.idBus,
    required this.monto,
    this.fechaTransaccion,
    this.sincronizadoOffline,
    this.latitud,
    this.longitud,
  });
}
