import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:intl/intl.dart';
import '../../model/EntradaHistorial.dart';
import 'TransactionTile.dart';

class EntradaHistorialTile extends StatelessWidget {
  final EntradaHistorial entrada;
  final bool mostrarTarjeta;

  const EntradaHistorialTile({
    super.key,
    required this.entrada,
    this.mostrarTarjeta = true,
  });

  static const _ambarFondo = Color(0xFFFFDDB3);
  static const _ambarTexto = Color(0xFF7A4A00);
  static const _azulFondo = Color(0xFFA8C7FA);
  static const _azulTexto = Color(0xFF0842A0);

  @override
  Widget build(BuildContext context) {
    if (entrada.tipo == TipoEntrada.pago) {
      return TransactionTile(
        transaccion: entrada.tx,
        mostrarTarjeta: mostrarTarjeta,
      );
    }

    final tx = entrada.tx;
    final prestado = entrada.tipo == TipoEntrada.emergencia;
    final saldado = tx.emergenciaPagada;

    final fondo = prestado ? _ambarFondo : _azulFondo;
    final color = prestado ? _ambarTexto : _azulTexto;
    final titulo = prestado
        ? 'PASAJE DE EMERGENCIA'
        : 'PASAJE DE EMERGENCIA PAGADO';
    final fecha = DateFormat('d MMM, h:mm a', 'es_CO').format(entrada.fecha);

    final nombreRuta = (tx.nombreRuta?.trim().isNotEmpty ?? false)
        ? tx.nombreRuta!.trim()
        : 'Ruta Urbana';

    final String detalle = prestado
        ? (saldado
              ? 'Te lo prestamos · ya saldado'
              : 'Te lo prestamos · pendiente de pago')
        : 'Saldado junto a tu pasaje · $nombreRuta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                prestado ? Icons.emergency : Icons.check_rounded,
                color: color,
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
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12),
                ),
                if (mostrarTarjeta && prestado && tx.tarjetaLabel != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tx.tarjetaLabel!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
            'COP ${NumberFormat('#,##0', 'es_CO').format(tx.monto)}',
            style: TextStyle(
              color: prestado ? color : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              // Si el préstamo ya se saldó, ese día no se cobró nada.
              decoration: prestado && saldado
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
