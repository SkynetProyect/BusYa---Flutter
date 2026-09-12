import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/TelemetriaGpsLog.dart';
import '../SupabaseServiceBase.dart';

class TelemetriaGpsLogService extends SupabaseServiceBase {
  Future<List<TelemetriaGpsLog>> getAll() => guard(() async {
    final data = await supabase.from('telemetria_gps_logs').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<TelemetriaGpsLog> getById(int id) => guard(() async {
    final data = await supabase
        .from('telemetria_gps_logs')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Registro de telemetría no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<TelemetriaGpsLog>> getByBusId(int idBus) => guard(() async {
    final data = await supabase
        .from('telemetria_gps_logs')
        .select()
        .eq('id_bus', idBus);
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<TelemetriaGpsLog> create(TelemetriaGpsLog item) => guard(() async {
    final data = await supabase
        .from('telemetria_gps_logs')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<TelemetriaGpsLog> update(TelemetriaGpsLog item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('telemetria_gps_logs')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('telemetria_gps_logs').delete().eq('id', id);
  });

  TelemetriaGpsLog _fromRow(Map<String, dynamic> row) => TelemetriaGpsLog(
    id: (row['id'] as num?)?.toInt(),
    idBus: row['id_bus'] as int?,
    coordenadas: Map<String, dynamic>.from(row['coordenadas'] as Map),
    timestamp: dateTime(row['timestamp']),
  );

  Map<String, dynamic> _toRow(TelemetriaGpsLog item) => {
    if (item.id != null) 'id': item.id,
    'id_bus': item.idBus,
    'coordenadas': item.coordenadas,
    'timestamp': item.timestamp?.toIso8601String(),
  };
}
