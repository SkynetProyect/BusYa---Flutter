import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/model/Ruta.dart';
import 'package:http/http.dart' as http;

class RutaService {
  // URL base del backend. Ajusta según tu entorno (dev/prod).
  static const String _baseUrl =
      'https://api.tuapp.com'; // cambiar esta madre despues
  static const String _endpoint = '/rutas';
  static const Duration _timeout = Duration(seconds: 8);

  // Headers reutilizables (agrega Authorization aquí si usas token)
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

  /// Obtener todas las rutas
  Future<List<Ruta>> getAll() {
    return _guard(() async {
      final response = await http.get(_uri(''), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener rutas: ${response.statusCode}');
      }
    });
  }

  /// Obtener una ruta por su id
  Future<Ruta> getById(int id) {
    return _guard(() async {
      final response = await http.get(_uri('/$id'), headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Ruta no encontrada');
      } else {
        throw Exception('Error al obtener la ruta: ${response.statusCode}');
      }
    });
  }

  /// Obtener todas las rutas de una empresa específica
  Future<List<Ruta>> getByEmpresaId(int idEmpresa) {
    return _guard(() async {
      final response = await http.get(
        _uri('/empresa/$idEmpresa'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener rutas de la empresa: ${response.statusCode}',
        );
      }
    });
  }

  /// Crear una nueva ruta
  Future<Ruta> create(Ruta ruta) {
    return _guard(() async {
      final response = await http.post(
        _uri(''),
        headers: _headers,
        body: jsonEncode(_toJson(ruta)),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception('Error al crear la ruta: ${response.statusCode}');
      }
    });
  }

  /// Actualizar una ruta existente
  Future<Ruta> update(Ruta ruta) {
    return _guard(() async {
      if (ruta.id == null) {
        throw Exception('No se puede actualizar una ruta sin id');
      }

      final response = await http.put(
        _uri('/${ruta.id}'),
        headers: _headers,
        body: jsonEncode(_toJson(ruta)),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception('Error al actualizar la ruta: ${response.statusCode}');
      }
    });
  }

  /// Eliminar una ruta por su id
  Future<void> delete(int id) {
    return _guard(() async {
      final response = await http.delete(_uri('/$id'), headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar la ruta: ${response.statusCode}');
      }
    });
  }

  // ---------- Helpers de serialización ----------

  Ruta _fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['id'] as int?,
      idEmpresa: json['idEmpresa'] as int,
      nombre: json['nombre'] as String,
      encodedPolyline: json['encodedPolyline'] as String,
      distancia: json['distancia'] as int,
      duracion: json['duracion'] as int,
    );
  }

  Map<String, dynamic> _toJson(Ruta ruta) {
    return {
      if (ruta.id != null) 'id': ruta.id,
      'idEmpresa': ruta.idEmpresa,
      'nombre': ruta.nombre,
      'encodedPolyline': ruta.encodedPolyline,
      'distancia': ruta.distancia,
      'duracion': ruta.duracion,
    };
  }
}
