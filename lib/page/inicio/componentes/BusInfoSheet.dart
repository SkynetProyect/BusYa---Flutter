import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Bus.dart' show Bus;

class BusInfoSheet extends StatelessWidget {
  final Bus bus;
  final Color markerColor;
  final String ocupacionTexto;
  final String? rutaNombre;

  const BusInfoSheet({
    super.key,
    required this.bus,
    required this.markerColor,
    required this.ocupacionTexto,
    this.rutaNombre,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: markerColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_bus, color: markerColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.placa,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (rutaNombre != null)
                        Text(
                          rutaNombre!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _infoRow(context, 'Ocupación', ocupacionTexto),
            _infoRow(context, 'Capacidad', '${bus.capacidadMaxima} pasajeros'),
            if (bus.nivelOcupacion != null)
              _infoRow(context, 'Nivel (crudo)', bus.nivelOcupacion!),
            if (bus.ultimaActualizacionGps != null)
              _infoRow(
                context,
                'Última actualización',
                _fmtDate(bus.ultimaActualizacionGps!),
              ),
            if (bus.latitudActual != null && bus.longitudActual != null)
              _infoRow(
                context,
                'Coordenadas',
                '${bus.latitudActual!.toStringAsFixed(6)}, ${bus.longitudActual!.toStringAsFixed(6)}',
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final styleLabel = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700);
    final styleValue = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: styleLabel)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: styleValue)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    // Simple ISO-like local formatting (no intl to keep dependencies minimal)
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
