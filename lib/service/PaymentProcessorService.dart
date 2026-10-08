// lib/service/PaymentProcessorService.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/PagoNfcResult.dart';
import '../model/Tarjeta.dart';

class PaymentProcessorService {
  // API desplegada en Render
  static const String _baseUrl =
      'https://busya-payment-simulated-api.onrender.com/api/payments';

  static const Duration _timeout = Duration(seconds: 60);

  Future<({bool ok, String message})> pagarEmergencia({
    required String idCliente,
    required int idTarjeta,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/emergency/pay'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'idClient': idCliente, 'idCard': idTarjeta}),
          )
          .timeout(_timeout);

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        final ok = data?['status'] == 'EMERGENCY_PAID';
        return (
          ok: ok,
          message:
              (data?['message'] ?? (ok ? 'Pasaje pagado' : 'No se pudo pagar'))
                  .toString(),
        );
      }

      return (
        ok: false,
        message:
            data?['message']?.toString() ??
            'Error del servidor de pagos (${response.statusCode})',
      );
    } on TimeoutException {
      return (
        ok: false,
        message: 'El servidor de pagos tardó demasiado. Intenta de nuevo.',
      );
    } catch (e) {
      return (ok: false, message: 'No se pudo conectar con pagos: $e');
    }
  }

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
            },
            body: jsonEncode(paymentPayload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PagoNfcResult.fromJson(data);
      }

      return PagoNfcResult(
        status: PagoNfcStatus.error,
        message: 'Error del servidor de pagos (${response.statusCode})',
      );
    } on TimeoutException {
      return PagoNfcResult(
        status: PagoNfcStatus.error,
        message:
            'El servidor de pagos tardó demasiado en responder. Intenta de nuevo.',
      );
    } catch (e) {
      return PagoNfcResult(
        status: PagoNfcStatus.error,
        message: 'No se pudo conectar con el microservicio de pagos: $e',
      );
    }
  }
}
