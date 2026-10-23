import 'package:flutter_application_1/model/TransaccionNfc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../SupabaseServiceBase.dart';

class TransaccionNfcService extends SupabaseServiceBase {
  final supabase = Supabase.instance.client;

  // Dos relaciones con tarjetas: la del cobro (id_tarjeta) y la que saldó
  // el pasaje de emergencia (id_tarjeta_pago_emergencia).
  static const _select =
      '*, tarjetas!id_tarjeta(marca, ultimos_cuatro_digitos), '
      'tarjeta_pago:tarjetas!id_tarjeta_pago_emergencia(marca, ultimos_cuatro_digitos), '
      'buses(id, id_ruta, rutas(nombre, precio_pasaje))';

  Future<Map<String, dynamic>?> getEmergenciaPendiente(String idUsuario) =>
      guard(() async {
        return await supabase
            .from('transacciones_nfc')
            .select('id, monto')
            .eq('id_usuario', idUsuario)
            .eq('es_emergencia', true)
            .eq('emergencia_pagada', false)
            .order('fecha_transaccion')
            .limit(1)
            .maybeSingle();
      });

  /// Historial completo del usuario
  Future<List<TransaccionNfc>> getHistorialPorUsuario(String idUsuario) =>
      guard(() async {
        final data = await supabase
            .from('transacciones_nfc')
            .select(_select)
            .eq('id_usuario', idUsuario)
            .order('fecha_transaccion', ascending: false);

        return (data as List)
            .map(
              (row) => TransaccionNfc.fromRow(Map<String, dynamic>.from(row)),
            )
            .toList();
      });

  /// Historial de una tarjeta: pagos normales hechos con ella y pasajes de
  /// emergencia que se saldaron con ella. Los préstamos sin pagar no entran.
  Future<List<TransaccionNfc>> getHistorialPorTarjeta(
    String idUsuario,
    int idTarjeta,
  ) => guard(() async {
    final data = await supabase
        .from('transacciones_nfc')
        .select(_select)
        .eq('id_usuario', idUsuario)
        .or(
          'and(es_emergencia.eq.false,id_tarjeta.eq.$idTarjeta),'
          'and(es_emergencia.eq.true,emergencia_pagada.eq.true,'
          'id_tarjeta_pago_emergencia.eq.$idTarjeta)',
        )
        .order('fecha_transaccion', ascending: false);

    return (data as List)
        .map((row) => TransaccionNfc.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  });
}
