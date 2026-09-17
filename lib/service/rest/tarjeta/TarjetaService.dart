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
      debugPrint(
        '[CARD DEBUG] PostgrestException code=${e.code}, message=${e.message}, '
        'details=${e.details}, hint=${e.hint}',
      );
      return e.message;
    }
    debugPrint('[CARD DEBUG] Exception type=${e.runtimeType}, error=$e');
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
      debugPrint(
        '[CARD DEBUG] loading cards idCliente=$idCliente, '
        'currentUserId=${supabase.auth.currentUser?.id}, '
        'userRole=${supabase.auth.currentUser?.role}',
      );
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
  Future<Tarjeta> create(Tarjeta tarjeta, {required String idCliente}) {
    return _guard(() async {
      final user = supabase.auth.currentUser;
      debugPrint(
        '[CARD DEBUG] create start passedIdCliente=$idCliente, '
        'tarjeta.idCliente=${tarjeta.idCliente}, '
        'currentUserId=${user?.id}, userRole=${user?.role}, '
        'hasSession=${supabase.auth.currentSession != null}',
      );
      if (user == null) {
        throw Exception('Debes iniciar sesión para registrar una tarjeta');
      }
      if (idCliente.isEmpty || idCliente != user.id) {
        throw Exception('La sesión del usuario no está disponible');
      }

      final payload = _toJson(tarjeta, idCliente: idCliente);
      debugPrint(
        '[CARD DEBUG] insert tarjetas payload keys=${payload.keys.toList()}, '
        'id_cliente=${payload['id_cliente']}, marca=${payload['marca']}, '
        'last4=${payload['ultimos_cuatro_digitos']}, '
        'fecha=${payload['fecha_vencimiento']}',
      );

      final data = await supabase
          .from('tarjetas')
          .insert(payload)
          .select()
          .single();
      debugPrint('[CARD DEBUG] insert succeeded returnedId=${data['id']}');
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
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para eliminar una tarjeta');
      }

      debugPrint('[CARD DEBUG] delete requested id=$id by user=${user.id}');

      // 1) Verificar existencia por id (puede devolver null si RLS impide leerla)
      final existing = await supabase
          .from('tarjetas')
          .select('id, id_cliente')
          .eq('id', id)
          .maybeSingle();

      if (existing == null) {
        debugPrint(
          '[CARD DEBUG] pre-check: tarjeta id=$id no visible (no existe o RLS no permite SELECT)',
        );
        throw Exception(
          'Tarjeta no encontrada o no tienes permiso de lectura (RLS).',
        );
      }

      final owner = existing['id_cliente'] as String?;
      if (owner != user.id) {
        debugPrint(
          '[CARD DEBUG] pre-check: tarjeta id=$id pertenece a otro usuario (owner=$owner, actual=${user.id})',
        );
        throw Exception(
          'La tarjeta pertenece a otro usuario (id_cliente=$owner, actual=${user.id}).',
        );
      }

      // 2) Borrar sin pedir representación para no depender de SELECT en RETURNING
      await supabase
          .from('tarjetas')
          .delete()
          .eq('id', id)
          .eq('id_cliente', user.id);

      // 3) Verificación posterior: ¿sigue existiendo?
      final after = await supabase
          .from('tarjetas')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      if (after != null) {
        debugPrint(
          '[CARD DEBUG] post-check: la tarjeta id=$id aún existe tras DELETE. Probable RLS DELETE faltante.',
        );
        throw Exception(
          'La eliminación no tuvo efecto (0 filas afectadas). Revisa la política DELETE en la tabla tarjetas.',
        );
      }

      debugPrint('[CARD DEBUG] delete finished id=$id');
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

  Map<String, dynamic> _toJson(Tarjeta tarjeta, {String? idCliente}) {
    return {
      if (tarjeta.id != null) 'id': tarjeta.id,
      'id_cliente': idCliente ?? tarjeta.idCliente,
      'marca': tarjeta.marca,
      'nombre_titular': tarjeta.nombreTitular,
      'ultimos_cuatro_digitos': tarjeta.ultimosCuatroDigitos,
      'fecha_vencimiento': tarjeta.fechaVencimiento,
    };
  }
}
