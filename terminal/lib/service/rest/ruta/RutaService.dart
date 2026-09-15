import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Ruta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RutaService {
  static const Duration _timeout = Duration(seconds: 8);

  /// Muestra un popup de error reutilizable
  void _showErrorDialog(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  /// Traduce excepciones comunes a mensajes legibles
  String _mensajeError(Object e) {
    if (e is TimeoutException) {
      return 'No se pudo conectar al servidor. Verifica tu conexión e intenta de nuevo.';
    }
    if (e is PostgrestException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// Envuelve cada llamada: aplica timeout y muestra popup si falla
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } catch (e) {
      final mensaje = _mensajeError(e);
      _showErrorDialog(mensaje);
      rethrow;
    }
  }

  /// Obtener todas las rutas
  Future<List<Ruta>> getAll() {
    return _guard(() async {
      final data = await supabase.from('rutas').select();
      return data
          .map((row) => _fromJson(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  /// Obtener una ruta por su id
  Future<Ruta> getById(int id) {
    return _guard(() async {
      final data = await supabase
          .from('rutas')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) throw Exception('Ruta no encontrada');
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Obtener todas las rutas de una empresa específica
  Future<List<Ruta>> getByEmpresaId(int idEmpresa) {
    return _guard(() async {
      final data = await supabase
          .from('rutas')
          .select()
          .eq('id_empresa', idEmpresa);
      return data
          .map((row) => _fromJson(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  /// Crear una nueva ruta
  Future<Ruta> create(Ruta ruta) {
    return _guard(() async {
      final data = await supabase
          .from('rutas')
          .insert(_toJson(ruta))
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Actualizar una ruta existente
  Future<Ruta> update(Ruta ruta) {
    return _guard(() async {
      if (ruta.id == null) {
        throw Exception('No se puede actualizar una ruta sin id');
      }

      final data = await supabase
          .from('rutas')
          .update(_toJson(ruta))
          .eq('id', ruta.id!)
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Eliminar una ruta por su id
  Future<void> delete(int id) {
    return _guard(() async {
      await supabase.from('rutas').delete().eq('id', id);
    });
  }

  // ---------- Helpers de serialización ----------

  Ruta _fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['id'] as int?,
      idEmpresa: json['id_empresa'] as int?,
      nombre: json['nombre'] as String,
      precioPasaje: (json['precio_pasaje'] as num?)?.toDouble() ?? 0,
      encodedPolyline: json['encoded_polyline'] as String?,
      distanciaMetros: json['distancia_metros'] as int?,
      duracionSegundos: json['duracion_segundos'] as int?,
    );
  }

  Map<String, dynamic> _toJson(Ruta ruta) {
    return {
      if (ruta.id != null) 'id': ruta.id,
      'id_empresa': ruta.idEmpresa,
      'nombre': ruta.nombre,
      'precio_pasaje': ruta.precioPasaje,
      'encoded_polyline': ruta.encodedPolyline,
      'distancia_metros': ruta.distanciaMetros,
      'duracion_segundos': ruta.duracionSegundos,
    };
  }
}
