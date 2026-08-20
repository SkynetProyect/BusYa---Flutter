import 'package:flutter_application_1/interfaces/EmpresaInterface.dart';

class Empresa implements EmpresaInterface {
  @override
  final int? id;
  @override
  final String nombre;

  Empresa({this.id, required this.nombre});
}
