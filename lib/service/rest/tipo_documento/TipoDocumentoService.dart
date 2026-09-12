import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/TipoDocumento.dart';
import '../SupabaseServiceBase.dart';

class TipoDocumentoService extends SupabaseServiceBase {
  Future<List<TipoDocumento>> getAll() => guard(() async {
    final data = await supabase.from('tipos_documento').select();
    return data.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  });

  Future<TipoDocumento> getById(int id) => guard(() async {
    final data = await supabase
        .from('tipos_documento')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) throw Exception('Tipo de documento no encontrado');
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<TipoDocumento> create(TipoDocumento item) => guard(() async {
    final data = await supabase
        .from('tipos_documento')
        .insert(_toRow(item))
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<TipoDocumento> update(TipoDocumento item) => guard(() async {
    if (item.id == null) throw Exception('No se puede actualizar sin id');
    final data = await supabase
        .from('tipos_documento')
        .update(_toRow(item))
        .eq('id', item.id!)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(data));
  });

  Future<void> delete(int id) => guard(() async {
    await supabase.from('tipos_documento').delete().eq('id', id);
  });

  TipoDocumento _fromRow(Map<String, dynamic> row) => TipoDocumento(
    id: row['id'] as int?,
    codigo: row['codigo'] as String,
    nombre: row['nombre'] as String,
  );

  Map<String, dynamic> _toRow(TipoDocumento item) => {
    if (item.id != null) 'id': item.id,
    'codigo': item.codigo,
    'nombre': item.nombre,
  };
}
