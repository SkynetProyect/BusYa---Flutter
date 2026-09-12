import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Usuario.dart';
import '../SupabaseServiceBase.dart';

class UsuarioService extends SupabaseServiceBase {
  Future<List<Usuario>> getAll() => guard(() async {
    final data = await supabase.from('usuarios').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<Usuario> getById(String id) => guard(() async {
    final data = await supabase
        .from('usuarios')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Usuario no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Usuario> create(Usuario item) => guard(() async {
    final data = await supabase
        .from('usuarios')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<Usuario> update(Usuario item) => guard(() async {
    final data = await supabase
        .from('usuarios')
        .update(_toRow(item))
        .eq('id', item.id)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(String id) => guard(() async {
    await supabase.from('usuarios').delete().eq('id', id);
  });

  Usuario _fromRow(Map<String, dynamic> row) => Usuario(
    id: row['id'] as String,
    idRol: row['id_rol'] as int?,
    idTipoDocumento: row['id_tipo_documento'] as int?,
    numeroDocumento: row['numero_documento'] as String,
    primerNombre: row['primer_nombre'] as String,
    primerApellido: row['primer_apellido'] as String,
    celular: row['celular'] as String?,
    puntosEco: row['puntos_eco'] as int?,
    createdAt: dateTime(row['created_at']),
  );

  Map<String, dynamic> _toRow(Usuario item) => {
    'id': item.id,
    'id_rol': item.idRol,
    'id_tipo_documento': item.idTipoDocumento,
    'numero_documento': item.numeroDocumento,
    'primer_nombre': item.primerNombre,
    'primer_apellido': item.primerApellido,
    'celular': item.celular,
    'puntos_eco': item.puntosEco,
  };
}
