import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcService {
  /// Verifica disponibilidad del hardware NFC en el dispositivo
  static Future<bool> isNfcAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Inicia la escucha activa de lectura NDEF para stickers NTAG215
  static Future<void> startSession({
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onError,
  }) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError(
        'El hardware NFC está desactivado o no está disponible en este dispositivo',
      );
      return;
    }

    NfcManager.instance.startSession(
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
          for (var record in message.records) {
            final payloadBytes = record.payload;
            final rawPayload = String.fromCharCodes(payloadBytes);

            if (rawPayload.contains('{') && rawPayload.contains('}')) {
              final jsonString = rawPayload.substring(
                rawPayload.indexOf('{'),
                rawPayload.lastIndexOf('}') + 1,
              );

              final Map<String, dynamic> parsedData = json.decode(jsonString);

              if (parsedData.containsKey('id_bus')) {
                onSuccess(parsedData);
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
