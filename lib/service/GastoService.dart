import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/ResumenGasto.dart';

class GastoService {
  /// [desde] inclusive, [hasta] exclusivo, en hora local del teléfono.
  Future<ResumenGasto> resumen({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final data = await supabase.rpc(
      'resumen_gasto',
      params: {
        'p_desde': desde.toUtc().toIso8601String(),
        'p_hasta': hasta.toUtc().toIso8601String(),
      },
    );

    if (data is! Map) {
      throw const FormatException('Respuesta inesperada de resumen_gasto');
    }
    return ResumenGasto.fromJson(Map<String, dynamic>.from(data));
  }
}
