import 'package:flutter_application_1/interfaces/TipoDocumentoInterface.dart';

class TipoDocumento implements TipoDocumentoInterface {
  @override
  final int? id;
  @override
  final String codigo;
  @override
  final String nombre;

  TipoDocumento({this.id, required this.codigo, required this.nombre});
}
