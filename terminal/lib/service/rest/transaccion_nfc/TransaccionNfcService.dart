import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/TransaccionNfc.dart';
import '../SupabaseServiceBase.dart';

class TransaccionNfcService extends SupabaseServiceBase {
  Future<List<TransaccionNfc>> getAll() => guard(() async {
    final data = await supabase.from('transacciones_nfc').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<TransaccionNfc> getById(String id) => guard(() async {
    final data = await supabase
        .from('transacciones_nfc')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Transacción NFC no encontrada');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<TransaccionNfc>> getByBilleteraId(String idBilletera) =>
      guard(() async {
        final data = await supabase
            .from('transacciones_nfc')
            .select()
            .eq('id_billetera', idBilletera);
        return data
            .map((row) => _fromRow(Map<String, dynamic>.from(row)))
            .toList();
      });

  Future<TransaccionNfc> create(TransaccionNfc item) => guard(() async {
    final data = await supabase
        .from('transacciones_nfc')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<TransaccionNfc> update(TransaccionNfc item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('transacciones_nfc')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(String id) => guard(() async {
    await supabase.from('transacciones_nfc').delete().eq('id', id);
  });

  TransaccionNfc _fromRow(Map<String, dynamic> row) => TransaccionNfc(
    id: row['id'] as String?,
    idBilletera: row['id_billetera'] as String?,
    idBus: row['id_bus'] as int?,
    monto: doubleValue(row['monto'])!,
    fechaTransaccion: dateTime(row['fecha_transaccion']),
    sincronizadoOffline: row['sincronizado_offline'] as bool?,
  );

  Map<String, dynamic> _toRow(TransaccionNfc item) => {
    if (item.id != null) 'id': item.id,
    'id_billetera': item.idBilletera,
    'id_bus': item.idBus,
    'monto': item.monto,
    'sincronizado_offline': item.sincronizadoOffline,
  };
}
