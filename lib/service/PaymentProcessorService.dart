// lib/service/rest/pago/PaymentProcessorService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../model/PagoNfcResult.dart';
import '../../../model/Tarjeta.dart';

class PaymentProcessorService {
  //  Actualiza esto cada vez que reinicies ngrok
  static const String _baseUrl =
      'https://willow-freeing-mushiness.ngrok-free.dev/api/payments';

  Future<PagoNfcResult> procesarPagoNfc({
    required Map<String, dynamic> dataNfc,
    required Tarjeta tarjetaSeleccionada,
    required String idCliente,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final int idBus = dataNfc['id_bus'] ?? 1;
      final double montoPasaje = (dataNfc['tarifa'] ?? 3207).toDouble();

      final Map<String, dynamic> paymentPayload = {
        'idClient': idCliente,
        'idCard': tarjetaSeleccionada.id,
        'idDevice': idBus,
        'amount': montoPasaje,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
      };

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(paymentPayload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PagoNfcResult.fromJson(data);
      }

      return PagoNfcResult(
        status: PagoNfcStatus.error,
        message: 'Error del servidor de pagos (${response.statusCode})',
      );
    } catch (e) {
      return PagoNfcResult(
        status: PagoNfcStatus.error,
        message: 'No se pudo conectar con el microservicio de pagos: $e',
      );
    }
  }
}
