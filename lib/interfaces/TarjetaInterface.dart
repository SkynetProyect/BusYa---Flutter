abstract class TarjetaInterface {
  final int? id;
  final int idCliente;
  final String marca;
  final String nombre;
  final int numero;
  final String vencimiento;

  TarjetaInterface({
    this.id,
    required this.idCliente,
    required this.marca,
    required this.nombre,
    required this.numero,
    required this.vencimiento,
  });
}
