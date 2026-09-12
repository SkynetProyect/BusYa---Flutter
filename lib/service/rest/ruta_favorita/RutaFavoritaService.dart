import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/RutaFavorita.dart';
import '../SupabaseServiceBase.dart';

class RutaFavoritaService extends SupabaseServiceBase {
  Future<List<RutaFavorita>> getAll() => guard(() async {
    final data = await supabase.from('rutas_favoritas').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<RutaFavorita> getById(int id) => guard(() async {
    final data = await supabase
        .from('rutas_favoritas')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Ruta favorita no encontrada');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<List<RutaFavorita>> getByUsuarioId(String idUsuario) =>
      guard(() async {
        final data = await supabase
            .from('rutas_favoritas')
            .select()
            .eq('id_usuario', idUsuario);
        return data
            .map((row) => _fromRow(Map<String, dynamic>.from(row)))
            .toList();
      });

  Future<RutaFavorita> create(RutaFavorita item) => guard(() async {
    final data = await supabase
        .from('rutas_favoritas')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<RutaFavorita> update(RutaFavorita item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('rutas_favoritas')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('rutas_favoritas').delete().eq('id', id);
  });

  RutaFavorita _fromRow(Map<String, dynamic> row) => RutaFavorita(
    id: row['id'] as int?,
    idUsuario: row['id_usuario'] as String?,
    idRuta: row['id_ruta'] as int?,
    createdAt: dateTime(row['created_at']),
  );

  Map<String, dynamic> _toRow(RutaFavorita item) => {
    if (item.id != null) 'id': item.id,
    'id_usuario': item.idUsuario,
    'id_ruta': item.idRuta,
  };
}
