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

  // Incrementa 1 punto tras validar un abordaje
  Future<void> sumarPuntoPorViaje() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final puntosActuales = await obtenerPuntos();

    await _supabase
        .from('usuarios')
        .update({'puntos_eco': puntosActuales + 1})
        .eq('id', user.id);
  }
}