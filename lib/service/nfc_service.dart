import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcService {
  /// Verifica que el NFC esté disponible Y encendido.
  static Future<bool> isNfcAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Inicia la escucha activa de lectura NDEF para stickers NTAG215
  static Future<void> startSession({
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onError,
  }) async {
    final availability = await NfcManager.instance.checkAvailability();

    if (availability == NfcAvailability.unsupported) {
      onError('Este dispositivo no tiene hardware NFC');
      return;
    }
    if (availability == NfcAvailability.disabled) {
      onError(
        'El NFC está desactivado. Actívalo en Ajustes e intenta de nuevo',
      );
      return;
    }

    await NfcManager.instance.startSession(
      // NTAG215 es ISO 14443 (tipo A), no necesitas iso15693
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            onError('El tag escaneado no es compatible con el estándar NDEF');
            await NfcManager.instance.stopSession();
            return;
          }

          final message = ndef.cachedMessage ?? await ndef.read();
          if (message == null || message.records.isEmpty) {
            onError('El sticker NFC está vacío o no contiene registros');
            await NfcManager.instance.stopSession();
            return;
          }

          // Procesar registros NDEF en busca del JSON del bus
          for (final record in message.records) {
            final rawPayload = utf8.decode(
              record.payload,
              allowMalformed: true,
            );

            // Extraer el JSON omitiendo el encabezado de idioma del registro de texto
            if (rawPayload.contains('{') && rawPayload.contains('}')) {
              final jsonString = rawPayload.substring(
                rawPayload.indexOf('{'),
                rawPayload.lastIndexOf('}') + 1,
              );

              final decoded = json.decode(jsonString);
              if (decoded is Map<String, dynamic> &&
                  decoded.containsKey('id_bus')) {
                onSuccess(decoded);
                await NfcManager.instance.stopSession();
                return;
              }
            }
          }

          onError(
            'El sticker NFC no contiene una identificación válida de bus',
          );
          await NfcManager.instance.stopSession();
        } catch (e) {
          onError('Error al procesar la lectura del chip NFC: $e');
          await NfcManager.instance.stopSession();
        }
      },
    );
  }

  /// Cancela y libera el hardware NFC
  static Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}
