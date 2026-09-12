import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Paradero.dart';
import '../SupabaseServiceBase.dart';

class ParaderoService extends SupabaseServiceBase {
  Future<List<Paradero>> getAll() => guard(() async {
    final data = await supabase.from('paraderos').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<Paradero> getById(int id) => guard(() async {
    final data = await supabase
        .from('paraderos')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Paradero no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Paradero> create(Paradero item) => guard(() async {
    final data = await supabase
        .from('paraderos')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Paradero> update(Paradero item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('paraderos')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('paraderos').delete().eq('id', id);
  });

  Paradero _fromRow(Map<String, dynamic> row) => Paradero(
    id: row['id'] as int?,
    nombre: row['nombre'] as String,
    latitud: doubleValue(row['latitud'])!,
    longitud: doubleValue(row['longitud'])!,
    direccionReferencia: row['direccion_referencia'] as String?,
  );

  Map<String, dynamic> _toRow(Paradero item) => {
    if (item.id != null) 'id': item.id,
    'nombre': item.nombre,
    'latitud': item.latitud,
    'longitud': item.longitud,
    'direccion_referencia': item.direccionReferencia,
  };
}
