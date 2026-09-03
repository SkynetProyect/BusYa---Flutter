import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String numeroDocumento,
    required String primerNombre,
    required String primerApellido,
    required int idTipoDocumento,
    required String celular,
    int? idRol,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<List<Map<String, dynamic>>> getTiposDocumento();
}
