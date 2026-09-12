import 'package:flutter_application_1/interfaces/RolInterface.dart';

class Rol implements RolInterface {
  @override
  final int? id;
  @override
  final String nombre;
  @override
  final String? descripcion;

  Rol({this.id, required this.nombre, this.descripcion});
}
