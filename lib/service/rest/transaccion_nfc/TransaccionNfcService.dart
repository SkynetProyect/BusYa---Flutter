import 'package:flutter_application_1/model/TransaccionNfc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../SupabaseServiceBase.dart';

class TransaccionNfcService extends SupabaseServiceBase {
  final supabase = Supabase.instance.client;

  static const _select =
      '*, tarjetas(marca, ultimos_cuatro_digitos), '
      'buses(id, id_ruta, rutas(nombre, precio_pasaje))';

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

  /// Historial de una tarjeta específica del usuario
  Future<List<TransaccionNfc>> getHistorialPorTarjeta(
    String idUsuario,
    int idTarjeta,
  ) => guard(() async {
    final data = await supabase
        .from('transacciones_nfc')
        .select(_select)
        .eq('id_usuario', idUsuario)
        .eq('id_tarjeta', idTarjeta)
        .order('fecha_transaccion', ascending: false);

    return (data as List)
        .map((row) => TransaccionNfc.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  });
}
