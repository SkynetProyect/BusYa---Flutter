import 'package:flutter_application_1/interfaces/TransaccionNfcInterface.dart';

class TransaccionNfc implements TransaccionNfcInterface {
  @override
  final String? id;
  @override
  final String? idBilletera;
  @override
  final int? idBus;
  @override
  final double monto;
  @override
  final DateTime? fechaTransaccion;
  @override
  final bool? sincronizadoOffline;

  TransaccionNfc({
    this.id,
    this.idBilletera,
    this.idBus,
    required this.monto,
    this.fechaTransaccion,
    this.sincronizadoOffline,
  });
}
