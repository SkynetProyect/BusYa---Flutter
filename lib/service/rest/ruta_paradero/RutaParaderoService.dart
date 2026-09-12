import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/RutaParadero.dart';
import '../SupabaseServiceBase.dart';

class RutaParaderoService extends SupabaseServiceBase {
  Future<List<RutaParadero>> getAll() => guard(() async {
    final data = await supabase.from('ruta_paraderos').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<RutaParadero> getById(int id) => guard(() async {
    final data = await supabase
        .from('ruta_paraderos')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Relación ruta-paradero no encontrada');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<RutaParadero>> getByRutaId(int idRuta) => guard(() async {
    final data = await supabase
        .from('ruta_paraderos')
        .select()
        .eq('id_ruta', idRuta)
        .order('orden_secuencia');
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<RutaParadero> create(RutaParadero item) => guard(() async {
    final data = await supabase
        .from('ruta_paraderos')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<RutaParadero> update(RutaParadero item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('ruta_paraderos')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('ruta_paraderos').delete().eq('id', id);
  });

  RutaParadero _fromRow(Map<String, dynamic> row) => RutaParadero(
    id: row['id'] as int?,
    idRuta: row['id_ruta'] as int?,
    idParadero: row['id_paradero'] as int?,
    ordenSecuencia: row['orden_secuencia'] as int,
  );

  Map<String, dynamic> _toRow(RutaParadero item) => {
    if (item.id != null) 'id': item.id,
    'id_ruta': item.idRuta,
    'id_paradero': item.idParadero,
    'orden_secuencia': item.ordenSecuencia,
  };
}
