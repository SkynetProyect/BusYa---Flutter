import 'package:flutter_application_1/model/Reporte.dart' show Reporte;
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD de [Reporte] contra la tabla "reportes" de Supabase.
///
/// El cliente llega por el constructor (por defecto usa el global),
/// así el servicio es fácil de probar con uno falso.
class ReporteService {
  final SupabaseClient _cliente;

  ReporteService([SupabaseClient? cliente])
    : _cliente = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _cliente.from('reportes');

  // READ: todos
  Future<List<Reporte>> listar() async {
    final filas = await _tabla.select().order('id');
    return filas.map((f) => Reporte.fromJson(f)).toList();
  }

  // READ: uno por id (null si no existe)
  Future<Reporte?> obtenerPorId(int id) async {
    final fila = await _tabla.select().eq('id', id).maybeSingle();
    return fila == null ? null : Reporte.fromJson(fila);
  }

  // READ: reportes de un usuario
  Future<List<Reporte>> listarPorUsuario(int idUsuario) async {
    final filas = await _tabla.select().eq('id_usuario', idUsuario).order('id');
    return filas.map((f) => Reporte.fromJson(f)).toList();
  }

  // CREATE: el id lo genera Supabase, por eso se quita del JSON.
  // Devuelve el reporte ya creado, con su id real.
  Future<Reporte> crear(Reporte reporte) async {
    final datos = reporte.toJson()..remove('id');
    final fila = await _tabla.insert(datos).select().single();
    return Reporte.fromJson(fila);
  }

  // UPDATE
  Future<void> actualizar(Reporte reporte) async {
    final datos = reporte.toJson()..remove('id');
    await _tabla.update(datos).eq('id', reporte.id);
  }

  // DELETE
  Future<void> eliminar(int id) async {
    await _tabla.delete().eq('id', id);
  }
}
