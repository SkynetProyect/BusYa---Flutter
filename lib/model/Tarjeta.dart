import 'package:flutter_application_1/interfaces/TarjetaInterface.dart';

class Tarjeta implements TarjetaInterface {
  @override
  final int? id;
  @override
  final int idCliente;
  @override
  final String marca;
  @override
  final String nombre;
  @override
  final int numero;
  @override
  final String vencimiento;

  Tarjeta({
    required this.id,
    required this.idCliente,
    required this.marca,
    required this.nombre,
    required this.numero,
    required this.vencimiento,
  });
}
