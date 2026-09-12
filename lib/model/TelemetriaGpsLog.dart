import 'package:flutter_application_1/interfaces/TelemetriaGpsLogInterface.dart';

class TelemetriaGpsLog implements TelemetriaGpsLogInterface {
  @override
  final int? id;
  @override
  final int? idBus;
  @override
  final Map<String, dynamic> coordenadas;
  @override
  final DateTime? timestamp;

  TelemetriaGpsLog({
    this.id,
    this.idBus,
    required this.coordenadas,
    this.timestamp,
  });
}
