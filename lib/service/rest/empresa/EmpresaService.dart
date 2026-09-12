import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Empresa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmpresaService {
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

  /// Obtener todas las empresas
  Future<List<Empresa>> getAll() {
    return _guard(() async {
      final data = await supabase.from('empresas').select();
      return data
          .map((row) => _fromJson(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  /// Obtener una empresa por su id
  Future<Empresa> getById(int id) {
    return _guard(() async {
      final data = await supabase
          .from('empresas')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) throw Exception('Empresa no encontrada');
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Crear una nueva empresa
  Future<Empresa> create(Empresa empresa) {
    return _guard(() async {
      final data = await supabase
          .from('empresas')
          .insert(_toJson(empresa))
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Actualizar una empresa existente
  Future<Empresa> update(Empresa empresa) {
    return _guard(() async {
      if (empresa.id == null) {
        throw Exception('No se puede actualizar una empresa sin id');
      }

      final data = await supabase
          .from('empresas')
          .update(_toJson(empresa))
          .eq('id', empresa.id!)
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Eliminar una empresa por su id
  Future<void> delete(int id) {
    return _guard(() async {
      await supabase.from('empresas').delete().eq('id', id);
    });
  }

  // ---------- Helpers de serialización ----------

  Empresa _fromJson(Map<String, dynamic> json) {
    return Empresa(id: json['id'] as int?, nombre: json['nombre'] as String);
  }

  Map<String, dynamic> _toJson(Empresa empresa) {
    return {if (empresa.id != null) 'id': empresa.id, 'nombre': empresa.nombre};
  }
}
