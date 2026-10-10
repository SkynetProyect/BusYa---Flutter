import 'package:supabase_flutter/supabase_flutter.dart';

class PuntosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Consulta el campo puntos_eco de la tabla usuarios para el usuario logueado
  Future<int> obtenerPuntos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final data = await _supabase
        .from('usuarios')
        .select('puntos_eco')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data['puntos_eco'] == null) return 0;
    return data['puntos_eco'] as int;
  }

  // Increments 1 point atomically after a successful purchase.
  // Returns the new balance, or null if it could not be saved.
  Future<int?> sumarPuntoPorViaje() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final nuevo = await _supabase.rpc('sumar_punto_eco');
      return nuevo as int?;
    } catch (_) {
      return null; // never block the payment because of points
    }
  }
}
