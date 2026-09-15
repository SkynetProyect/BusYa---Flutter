import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseServiceBase {
  static const Duration timeout = Duration(seconds: 8);

  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(timeout);
    } catch (error) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage(error)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
      rethrow;
    }
  }

  String errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  DateTime? dateTime(Object? value) {
    if (value == null) return null;
    return value is DateTime ? value : DateTime.tryParse(value.toString());
  }

  double? doubleValue(Object? value) {
    if (value == null) return null;
    return value is num ? value.toDouble() : double.tryParse(value.toString());
  }
}
