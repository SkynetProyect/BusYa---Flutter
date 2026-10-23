import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:intl/intl.dart';
import '../../model/EntradaHistorial.dart';
import 'TransactionTile.dart';

class EntradaHistorialTile extends StatelessWidget {
  final EntradaHistorial entrada;

  /// true = historial general, false = historial de una tarjeta
  final bool mostrarTarjeta;

  const EntradaHistorialTile({
    super.key,
    required this.entrada,
    this.mostrarTarjeta = true,
  });

  @override
  Widget build(BuildContext context) {
    // Pagos normales: tu tile de siempre, sin tocar.
    if (entrada.tipo == TipoEntrada.pago) {
      return TransactionTile(
        transaccion: entrada.tx,
        mostrarTarjeta: mostrarTarjeta,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    // En claro se oscurece un poco el acento del texto para el contraste.
    Color textoAcento(Color c) =>
        dark ? c : Color.alphaBlend(Colors.black.withValues(alpha: 0.22), c);
    final warning = dark ? AppColors.darkWarning : AppColors.warning;
    final info = dark ? AppColors.darkInfo : AppColors.info;
    final textoSec = dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final divisor = dark ? AppColors.darkDivider : AppColors.borderSoft;

    final tx = entrada.tx;
    final prestado = entrada.tipo == TipoEntrada.emergencia;
    final saldado = tx.emergenciaPagada;

    final ruta = (tx.nombreRuta?.trim().isNotEmpty ?? false)
        ? tx.nombreRuta!.trim()
        : 'Ruta Urbana';
    final fecha = DateFormat('d MMM, h:mm a', 'es_CO').format(entrada.fecha);

    final acento = prestado ? warning : info;
    final acentoTexto = textoAcento(acento);

    final String titulo = prestado
        ? 'PASAJE DE EMERGENCIA'
        : (mostrarTarjeta ? 'PASAJE DE EMERGENCIA PAGADO' : ruta.toUpperCase());

    final Color montoColor = prestado
        ? (saldado ? textoSec : acentoTexto)
        : scheme.primary;

    final Widget detalle;
    if (prestado) {
      detalle = saldado
          ? _linea(Icons.check_rounded, 'Saldado', textoSec)
          : _linea(
              Icons.warning_amber_rounded,
              'Pendiente de pago',
              acentoTexto,
              negrita: true,
            );
    } else if (mostrarTarjeta) {
      detalle = _linea(
        Icons.credit_card,
        'Saldado con ${tx.tarjetaPagoLabel ?? 'tarjeta eliminada'}',
        acentoTexto,
      );
    } else {
      detalle = _linea(
        Icons.emergency,
        'Pasaje de emergencia',
        acentoTexto,
        negrita: true,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divisor, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: acento.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                prestado ? Icons.emergency : Icons.verified_outlined,
                color: acentoTexto,
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
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(fecha, style: TextStyle(color: textoSec, fontSize: 12)),
                const SizedBox(height: 2),
                detalle,
              ],
            ),
          ),
          Text(
            'COP ${NumberFormat('#,##0', 'es_CO').format(tx.monto)}',
            style: TextStyle(
              color: montoColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              decoration: prestado && saldado
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linea(
    IconData icono,
    String texto,
    Color color, {
    bool negrita = false,
  }) {
    return Row(
      children: [
        Icon(icono, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: negrita ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
