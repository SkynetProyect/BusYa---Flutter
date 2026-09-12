import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/ParaderoFavorito.dart';
import '../SupabaseServiceBase.dart';

class ParaderoFavoritoService extends SupabaseServiceBase {
  Future<List<ParaderoFavorito>> getAll() => guard(() async {
    final data = await supabase.from('paraderos_favoritos').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<ParaderoFavorito> getById(int id) => guard(() async {
    final data = await supabase
        .from('paraderos_favoritos')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Paradero favorito no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<ParaderoFavorito>> getByUsuarioId(String idUsuario) =>
      guard(() async {
        final data = await supabase
            .from('paraderos_favoritos')
            .select()
            .eq('id_usuario', idUsuario);
        return data
            .map((row) => _fromRow(Map<String, dynamic>.from(row)))
            .toList();
      });

  Future<ParaderoFavorito> create(ParaderoFavorito item) => guard(() async {
    final data = await supabase
        .from('paraderos_favoritos')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<ParaderoFavorito> update(ParaderoFavorito item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('paraderos_favoritos')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('paraderos_favoritos').delete().eq('id', id);
  });

  ParaderoFavorito _fromRow(Map<String, dynamic> row) => ParaderoFavorito(
    id: row['id'] as int?,
    idUsuario: row['id_usuario'] as String?,
    idParadero: row['id_paradero'] as int?,
    createdAt: dateTime(row['created_at']),
  );

  Map<String, dynamic> _toRow(ParaderoFavorito item) => {
    if (item.id != null) 'id': item.id,
    'id_usuario': item.idUsuario,
    'id_paradero': item.idParadero,
  };
}
