abstract class TelemetriaGpsLogInterface {
  final int? id;
  final int? idBus;
  final Map<String, dynamic> coordenadas;
  final DateTime? timestamp;

  TelemetriaGpsLogInterface({
    this.id,
    this.idBus,
    required this.coordenadas,
    this.timestamp,
  });
}
