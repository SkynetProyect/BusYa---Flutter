abstract class RutaInterface {
  final int? id;
  final int idEmpresa;
  final String nombre;
  final String encodedPolyline;
  final int distancia;
  final int duracion;

  RutaInterface({
    this.id,
    required this.idEmpresa,
    required this.nombre,
    required this.encodedPolyline,
    required this.distancia,
    required this.duracion,
  });
}
