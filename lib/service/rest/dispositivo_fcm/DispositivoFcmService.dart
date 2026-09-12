import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/DispositivoFcm.dart';
import '../SupabaseServiceBase.dart';

class DispositivoFcmService extends SupabaseServiceBase {
  Future<List<DispositivoFcm>> getAll() => guard(() async {
    final data = await supabase.from('dispositivos_fcm').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<DispositivoFcm> getById(int id) => guard(() async {
    final data = await supabase
        .from('dispositivos_fcm')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Dispositivo FCM no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<DispositivoFcm>> getByUsuarioId(String idUsuario) =>
      guard(() async {
        final data = await supabase
            .from('dispositivos_fcm')
            .select()
            .eq('id_usuario', idUsuario);
        return data
            .map((row) => _fromRow(Map<String, dynamic>.from(row)))
            .toList();
      });

  Future<DispositivoFcm> create(DispositivoFcm item) => guard(() async {
    final data = await supabase
        .from('dispositivos_fcm')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<DispositivoFcm> update(DispositivoFcm item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('dispositivos_fcm')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('dispositivos_fcm').delete().eq('id', id);
  });

  DispositivoFcm _fromRow(Map<String, dynamic> row) => DispositivoFcm(
    id: row['id'] as int?,
    idUsuario: row['id_usuario'] as String?,
    fcmToken: row['fcm_token'] as String,
    plataforma: row['plataforma'] as String?,
    updatedAt: dateTime(row['updated_at']),
  );

  Map<String, dynamic> _toRow(DispositivoFcm item) => {
    if (item.id != null) 'id': item.id,
    'id_usuario': item.idUsuario,
    'fcm_token': item.fcmToken,
    'plataforma': item.plataforma,
  };
}
