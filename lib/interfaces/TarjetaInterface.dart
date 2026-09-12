abstract class TarjetaInterface {
  final int? id;
  final String? idCliente;
  final String marca;
  final String nombreTitular;
  final String ultimosCuatroDigitos;
  final String fechaVencimiento;

  TarjetaInterface({
    this.id,
    this.idCliente,
    required this.marca,
    required this.nombreTitular,
    required this.ultimosCuatroDigitos,
    required this.fechaVencimiento,
  });
}
