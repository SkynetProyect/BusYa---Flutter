import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<void> startSession({
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onError,
  }) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError('El dispositivo no cuenta con hardware NFC habilitado');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            onError('Tag NFC no compatible con lectura NDEF');
            await NfcManager.instance.stopSession();
            return;
          }

          final message = ndef.cachedMessage ?? await ndef.read();
          if (message == null || message.records.isEmpty) {
            onError('El tag NFC está vacío');
            await NfcManager.instance.stopSession();
            return;
          }

          for (var record in message.records) {
            final payloadBytes = record.payload;

            final rawPayload = String.fromCharCodes(payloadBytes);

            if (rawPayload.contains('{')) {
              final jsonString = rawPayload.substring(rawPayload.indexOf('{'));
              final Map<String, dynamic> parsedData = json.decode(jsonString);

              onSuccess(parsedData);
              await NfcManager.instance.stopSession();
              return;
            }
          }

          final tagIdentifier = tag.data['ndef']?['identifier'];
          onSuccess({'id_bus': 1, 'tag_identifier': tagIdentifier});

          await NfcManager.instance.stopSession();
        } catch (e) {
          onError('Error al leer el tag NFC: $e');
          await NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      },
    );
  }

  static Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}
