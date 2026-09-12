import 'package:flutter_application_1/interfaces/TarjetaInterface.dart';

class Tarjeta implements TarjetaInterface {
  @override
  final int? id;
  @override
  final String? idCliente;
  @override
  final String marca;
  @override
  final String nombreTitular;
  @override
  final String ultimosCuatroDigitos;
  @override
  final String fechaVencimiento;

  Tarjeta({
    required this.id,
    this.idCliente,
    required this.marca,
    required this.nombreTitular,
    required this.ultimosCuatroDigitos,
    required this.fechaVencimiento,
  });
}
