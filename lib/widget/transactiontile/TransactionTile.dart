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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E9E5), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.directions_bus,
                color: AppColors.primary,
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
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: Color(0xFF68736D),
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
                            ? const Color(0xFFE57373)
                            : const Color(0xFF68736D),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          metodoPago,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: esEmergencia
                                ? const Color(0xFFE57373)
                                : const Color(0xFF68736D),
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
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
