import 'package:flutter_application_1/interfaces/UsuarioInterface.dart';

class Usuario implements UsuarioInterface {
  @override
  final String id;
  @override
  final int? idRol;
  @override
  final int? idTipoDocumento;
  @override
  final String numeroDocumento;
  @override
  final String primerNombre;
  @override
  final String primerApellido;
  @override
  final String? celular;
  @override
  final int? puntosEco;
  @override
  final DateTime? createdAt;

  Usuario({
    required this.id,
    this.idRol,
    this.idTipoDocumento,
    required this.numeroDocumento,
    required this.primerNombre,
    required this.primerApellido,
    this.celular,
    this.puntosEco,
    this.createdAt,
  });
}
