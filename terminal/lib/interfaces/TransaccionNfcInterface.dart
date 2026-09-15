abstract class TransaccionNfcInterface {
  final String? id;
  final String? idBilletera;
  final int? idBus;
  final double monto;
  final DateTime? fechaTransaccion;
  final bool? sincronizadoOffline;

  TransaccionNfcInterface({
    this.id,
    this.idBilletera,
    this.idBus,
    required this.monto,
    this.fechaTransaccion,
    this.sincronizadoOffline,
  });
}
