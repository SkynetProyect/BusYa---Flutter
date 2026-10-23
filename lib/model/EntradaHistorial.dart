import 'TransaccionNfc.dart';

enum TipoEntrada { pago, emergencia, emergenciaPagada }

class EntradaHistorial {
  final TransaccionNfc tx;
  final TipoEntrada tipo;
  final DateTime fecha;
  const EntradaHistorial(this.tx, this.tipo, this.fecha);
}

List<EntradaHistorial> expandirHistorial(List<TransaccionNfc> lista) {
  final out = <EntradaHistorial>[];
  final sinFecha = DateTime.fromMillisecondsSinceEpoch(0);
  for (final t in lista) {
    final f = t.fechaTransaccion ?? sinFecha;
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
