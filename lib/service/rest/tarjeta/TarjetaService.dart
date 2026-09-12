import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TarjetaService {
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

  /// Obtener todas las tarjetas
  Future<List<Tarjeta>> getAll() {
    return _guard(() async {
      final data = await supabase.from('tarjetas').select();
      return data
          .map((row) => _fromJson(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  /// Obtener una tarjeta por su id
  Future<Tarjeta> getById(int id) {
    return _guard(() async {
      final data = await supabase
          .from('tarjetas')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) throw Exception('Tarjeta no encontrada');
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Obtener todas las tarjetas de un cliente específico
  Future<List<Tarjeta>> getByClienteId(String idCliente) {
    return _guard(() async {
      final data = await supabase
          .from('tarjetas')
          .select()
          .eq('id_cliente', idCliente);
      return data
          .map((row) => _fromJson(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  /// Crear una nueva tarjeta
  Future<Tarjeta> create(Tarjeta tarjeta) {
    return _guard(() async {
      final data = await supabase
          .from('tarjetas')
          .insert(_toJson(tarjeta))
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Actualizar una tarjeta existente
  Future<Tarjeta> update(Tarjeta tarjeta) {
    return _guard(() async {
      if (tarjeta.id == null) {
        throw Exception('No se puede actualizar una tarjeta sin id');
      }

      final data = await supabase
          .from('tarjetas')
          .update(_toJson(tarjeta))
          .eq('id', tarjeta.id!)
          .select()
          .single();
      return _fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Eliminar una tarjeta por su id
  Future<void> delete(int id) {
    return _guard(() async {
      await supabase.from('tarjetas').delete().eq('id', id);
    });
  }

  // ---------- Helpers de serialización ----------

  Tarjeta _fromJson(Map<String, dynamic> json) {
    return Tarjeta(
      id: json['id'] as int?,
      idCliente: json['id_cliente'] as String?,
      marca: json['marca'] as String,
      nombreTitular: json['nombre_titular'] as String,
      ultimosCuatroDigitos: json['ultimos_cuatro_digitos'] as String,
      fechaVencimiento: json['fecha_vencimiento'] as String,
    );
  }

  Map<String, dynamic> _toJson(Tarjeta tarjeta) {
    return {
      if (tarjeta.id != null) 'id': tarjeta.id,
      'id_cliente': tarjeta.idCliente,
      'marca': tarjeta.marca,
      'nombre_titular': tarjeta.nombreTitular,
      'ultimos_cuatro_digitos': tarjeta.ultimosCuatroDigitos,
      'fecha_vencimiento': tarjeta.fechaVencimiento,
    };
  }
}
