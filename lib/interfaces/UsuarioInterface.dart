abstract class UsuarioInterface {
  final String id;
  final int? idRol;
  final int? idTipoDocumento;
  final String numeroDocumento;
  final String primerNombre;
  final String primerApellido;
  final String? celular;
  final int? puntosEco;
  final DateTime? createdAt;

  UsuarioInterface({
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
