import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../model/TransaccionNfc.dart';

class TransactionTile extends StatelessWidget {
  final TransaccionNfc transaccion;

  /// En el historial por tarjeta se puede poner en false: ya s
  final bool mostrarTarjeta;

  const TransactionTile({
    super.key,
    required this.transaccion,
    this.mostrarTarjeta = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final nombreRuta = (transaccion.nombreRuta?.trim().isNotEmpty ?? false)
        ? transaccion.nombreRuta!.trim()
        : 'Ruta Urbana';

    final fecha = transaccion.fechaTransaccion != null
        ? DateFormat(
            'd MMM, h:mm a',
            'es_CO',
          ).format(transaccion.fechaTransaccion!.toLocal())
        : 'Reciente';

    final esEmergencia = transaccion.esEmergencia;

    // Con qué se pagó
    final String metodoPago =
        transaccion.tarjetaLabel ??
        (esEmergencia ? 'Pasaje de emergencia' : 'Tarjeta eliminada');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurfaceGreen
                  : AppColors.surfaceMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.directions_bus,
                color: colors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreRuta.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fecha,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
                if (mostrarTarjeta) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        esEmergencia
                            ? Icons.warning_amber_rounded
                            : Icons.credit_card,
                        size: 12,
                        color: esEmergencia
                            ? colors.error
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          metodoPago,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: esEmergencia
                                ? colors.error
                                : colors.onSurface.withValues(alpha: 0.72),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            'COP ${NumberFormat('#,##0', 'es_CO').format(transaccion.monto)}',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
