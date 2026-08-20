import 'dart:convert';
import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';

class TarjetaService {
  static const String _baseUrl =
      'https://api.tuapp.com'; // cambiar esta madre despues
  static const String _endpoint = '/tarjetas';
  static const Duration _timeout = Duration(seconds: 8);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$_endpoint$path');

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
    if (e is http.ClientException) {
      return 'Error de red. Verifica tu conexión a internet.';
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
      final response = await http.get(_uri(''), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tarjetas: ${response.statusCode}');
      }
    });
  }

  /// Obtener una tarjeta por su id
  Future<Tarjeta> getById(int id) {
    return _guard(() async {
      final response = await http.get(_uri('/$id'), headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Tarjeta no encontrada');
      } else {
        throw Exception('Error al obtener la tarjeta: ${response.statusCode}');
      }
    });
  }

  /// Obtener todas las tarjetas de un cliente específico
  Future<List<Tarjeta>> getByClienteId(int idCliente) {
    return _guard(() async {
      final response = await http.get(
        _uri('/cliente/$idCliente'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener tarjetas del cliente: ${response.statusCode}',
        );
      }
    });
  }

  /// Crear una nueva tarjeta
  Future<Tarjeta> create(Tarjeta tarjeta) {
    return _guard(() async {
      final response = await http.post(
        _uri(''),
        headers: _headers,
        body: jsonEncode(_toJson(tarjeta)),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception('Error al crear la tarjeta: ${response.statusCode}');
      }
    });
  }

  /// Actualizar una tarjeta existente
  Future<Tarjeta> update(Tarjeta tarjeta) {
    return _guard(() async {
      if (tarjeta.id == null) {
        throw Exception('No se puede actualizar una tarjeta sin id');
      }

      final response = await http.put(
        _uri('/${tarjeta.id}'),
        headers: _headers,
        body: jsonEncode(_toJson(tarjeta)),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception(
          'Error al actualizar la tarjeta: ${response.statusCode}',
        );
      }
    });
  }

  /// Eliminar una tarjeta por su id
  Future<void> delete(int id) {
    return _guard(() async {
      final response = await http.delete(_uri('/$id'), headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar la tarjeta: ${response.statusCode}');
      }
    });
  }

  // ---------- Helpers de serialización ----------

  Tarjeta _fromJson(Map<String, dynamic> json) {
    return Tarjeta(
      id: json['id'] as int?,
      idCliente: json['idCliente'] as int,
      marca: json['marca'] as String,
      nombre: json['nombre'] as String,
      numero: json['numero'] as int,
      vencimiento: json['vencimiento'] as String,
    );
  }

  Map<String, dynamic> _toJson(Tarjeta tarjeta) {
    return {
      if (tarjeta.id != null) 'id': tarjeta.id,
      'idCliente': tarjeta.idCliente,
      'marca': tarjeta.marca,
      'nombre': tarjeta.nombre,
      'numero': tarjeta.numero,
      'vencimiento': tarjeta.vencimiento,
    };
  }
}
