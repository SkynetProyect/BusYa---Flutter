import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Bus.dart';
import '../SupabaseServiceBase.dart';

class BusService extends SupabaseServiceBase {
  Future<List<Bus>> getAll() => guard(() async {
    final data = await supabase.from('buses').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<Bus> getById(int id) => guard(() async {
    final data = await supabase
        .from('buses')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Bus no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<Bus>> getByRutaId(int idRuta) => guard(() async {
    final data = await supabase.from('buses').select().eq('id_ruta', idRuta);
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<Bus> create(Bus item) => guard(() async {
    final data = await supabase
        .from('buses')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Bus> update(Bus item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('buses')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('buses').delete().eq('id', id);
  });

  Bus _fromRow(Map<String, dynamic> row) => Bus(
    id: row['id'] as int?,
    idRuta: row['id_ruta'] as int?,
    placa: row['placa'] as String,
    capacidadMaxima: row['capacidad_maxima'] as int,
    nivelOcupacion: _normalizeOcupacion(row['nivel_ocupacion']),
    latitudActual: doubleValue(row['latitud_actual']),
    longitudActual: doubleValue(row['longitud_actual']),
    ultimaActualizacionGps: dateTime(row['ultima_actualizacion_gps']),
  );

  String? _normalizeOcupacion(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw.trim();
    if (raw is num) return raw.toString();
    return raw.toString();
  }

  Map<String, dynamic> _toRow(Bus item) => {
    if (item.id != null) 'id': item.id,
    'id_ruta': item.idRuta,
    'placa': item.placa,
    'capacidad_maxima': item.capacidadMaxima,
    'nivel_ocupacion': item.nivelOcupacion,
    'latitud_actual': item.latitudActual,
    'longitud_actual': item.longitudActual,
    'ultima_actualizacion_gps': item.ultimaActualizacionGps?.toIso8601String(),
  };
}
