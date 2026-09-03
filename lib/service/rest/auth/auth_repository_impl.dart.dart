import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  User? get currentUser => supabase.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String numeroDocumento,
    required String primerNombre,
    required String primerApellido,
    required int idTipoDocumento,
    required String celular,
    int? idRol,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final String? userId = response.user?.id;

      if (userId != null) {
        await supabase.from('usuarios').insert({
          'id': userId,
          'id_rol': idRol ?? 1,
          'id_tipo_documento': idTipoDocumento,
          'numero_documento': numeroDocumento,
          'primer_nombre': primerNombre,
          'primer_apellido': primerApellido,
          'celular': celular,
          'puntos_eco': 0,
        });
      }

      return response;
    } on AuthException catch (error) {
      throw AuthException(error.message);
    } catch (error) {
      throw Exception('Error en la base de datos: $error');
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Future<List<Map<String, dynamic>>> getTiposDocumento() async {
    final data = await supabase
        .from('tipos_documento')
        .select('id, codigo, nombre');
    return List<Map<String, dynamic>>.from(data);
  }
}
