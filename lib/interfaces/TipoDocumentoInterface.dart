abstract class TipoDocumentoInterface {
  final int? id;
  final String codigo;
  final String nombre;

  TipoDocumentoInterface({this.id, required this.codigo, required this.nombre});
}
