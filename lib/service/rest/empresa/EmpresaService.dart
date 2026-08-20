import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_keys.dart';
import 'package:flutter_application_1/model/Empresa.dart';
import 'package:http/http.dart' as http;

class EmpresaService {
  // URL base del backend. Ajusta según tu entorno (dev/prod).
  static const String _baseUrl =
      'https://api.tuapp.com'; // cambiar esta madre despues
  static const String _endpoint = '/empresas';
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

  /// Obtener todas las empresas
  Future<List<Empresa>> getAll() {
    return _guard(() async {
      final response = await http.get(_uri(''), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener empresas: ${response.statusCode}');
      }
    });
  }

  /// Obtener una empresa por su id
  Future<Empresa> getById(int id) {
    return _guard(() async {
      final response = await http.get(_uri('/$id'), headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Empresa no encontrada');
      } else {
        throw Exception('Error al obtener la empresa: ${response.statusCode}');
      }
    });
  }

  /// Crear una nueva empresa
  Future<Empresa> create(Empresa empresa) {
    return _guard(() async {
      final response = await http.post(
        _uri(''),
        headers: _headers,
        body: jsonEncode(_toJson(empresa)),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception('Error al crear la empresa: ${response.statusCode}');
      }
    });
  }

  /// Actualizar una empresa existente
  Future<Empresa> update(Empresa empresa) {
    return _guard(() async {
      if (empresa.id == null) {
        throw Exception('No se puede actualizar una empresa sin id');
      }

      final response = await http.put(
        _uri('/${empresa.id}'),
        headers: _headers,
        body: jsonEncode(_toJson(empresa)),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _fromJson(data);
      } else {
        throw Exception(
          'Error al actualizar la empresa: ${response.statusCode}',
        );
      }
    });
  }

  /// Eliminar una empresa por su id
  Future<void> delete(int id) {
    return _guard(() async {
      final response = await http.delete(_uri('/$id'), headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar la empresa: ${response.statusCode}');
      }
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
