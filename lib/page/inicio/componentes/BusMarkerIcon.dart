import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Bus.dart' show Bus;
import 'package:flutter_application_1/page/inicio/componentes/OccupancyFormater.dart'
    show OccupancyFormatter;

/// Icono de un bus en el mapa, coloreado según su ocupación.
/// Muestra un tooltip con placa y ocupación y notifica el tap.
class BusMarkerIcon extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;

  const BusMarkerIcon({super.key, required this.bus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message:
            '${bus.placa}: ${OccupancyFormatter.label(bus.nivelOcupacion)}',
        child: Icon(
          Icons.directions_bus,
          color: OccupancyFormatter.color(bus.nivelOcupacion),
          size: 30,
        ),
      ),
    );
  }
}
