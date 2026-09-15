import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    print('--- DEBUG SUPABASE CONFIG ---');
    print('URL: $supabaseUrl');
    print('KEY LENGTH: ${supabaseAnonKey.length}');
    print('-----------------------------');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Error: Faltan las credenciales de Supabase en el archivo .env',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

//atajo global para acceder a la instancia de Supabase desde cualquier parte de la aplicación
SupabaseClient get supabase => Supabase.instance.client;
