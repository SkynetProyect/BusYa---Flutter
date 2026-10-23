import 'TransaccionNfc.dart';

enum TipoEntrada { pago, emergencia, emergenciaPagada }

class EntradaHistorial {
  final TransaccionNfc tx;
  final TipoEntrada tipo;
  final DateTime fecha;
  const EntradaHistorial(this.tx, this.tipo, this.fecha);
}

final _sinFecha = DateTime.fromMillisecondsSinceEpoch(0);

/// Historial general: una emergencia pagada se muestra como dos eventos,
/// el préstamo y el pago.
List<EntradaHistorial> expandirHistorial(List<TransaccionNfc> lista) {
  final out = <EntradaHistorial>[];
  for (final t in lista) {
    final f = t.fechaTransaccion ?? _sinFecha;
    if (!t.esEmergencia) {
      out.add(EntradaHistorial(t, TipoEntrada.pago, f));
      continue;
    }
    out.add(EntradaHistorial(t, TipoEntrada.emergencia, f));
    if (t.emergenciaPagada && t.fechaPagoEmergencia != null) {
      out.add(
        EntradaHistorial(
          t,
          TipoEntrada.emergenciaPagada,
          t.fechaPagoEmergencia!,
        ),
      );
    }
  }
  out.sort((a, b) => b.fecha.compareTo(a.fecha));
  return out;
}

/// Historial de una tarjeta: el préstamo no se muestra (no es de ninguna
/// tarjeta); la emergencia solo aparece el día que se pagó con esta tarjeta.
List<EntradaHistorial> expandirHistorialTarjeta(
  List<TransaccionNfc> lista,
  int idTarjeta,
) {
  final out = <EntradaHistorial>[];
  for (final t in lista) {
    if (!t.esEmergencia) {
      if (t.idTarjeta == idTarjeta) {
        out.add(
          EntradaHistorial(
            t,
            TipoEntrada.pago,
            t.fechaTransaccion ?? _sinFecha,
          ),
        );
      }
      continue;
    }
    if (t.emergenciaPagada &&
        t.idTarjetaPagoEmergencia == idTarjeta &&
        t.fechaPagoEmergencia != null) {
      out.add(
        EntradaHistorial(
          t,
          TipoEntrada.emergenciaPagada,
          t.fechaPagoEmergencia!,
        ),
      );
    }
  }
  out.sort((a, b) => b.fecha.compareTo(a.fecha));
  return out;
}
