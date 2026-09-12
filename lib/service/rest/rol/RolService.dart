import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Rol.dart';
import '../SupabaseServiceBase.dart';

class RolService extends SupabaseServiceBase {
  Future<List<Rol>> getAll() => guard(() async {
    final data = await supabase.from('roles').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<Rol> getById(int id) => guard(() async {
    final data = await supabase
        .from('roles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Rol no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Rol> create(Rol item) => guard(() async {
    final data = await supabase
        .from('roles')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Rol> update(Rol item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('roles')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('roles').delete().eq('id', id);
  });

  Rol _fromRow(Map<String, dynamic> row) => Rol(
    id: row['id'] as int?,
    nombre: row['nombre'] as String,
    descripcion: row['descripcion'] as String?,
  );

  Map<String, dynamic> _toRow(Rol item) => {
    if (item.id != null) 'id': item.id,
    'nombre': item.nombre,
    'descripcion': item.descripcion,
  };
}
