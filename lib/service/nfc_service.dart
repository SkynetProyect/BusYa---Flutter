import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcService {
  static Object? _owner;

  static bool isOwner(Object o) => identical(_owner, o);

  static Future<bool> isNfcAvailable() async =>
      await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;

  static Future<void> startSession({
    required Object owner,
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

    // Si otra pantalla tenía la sesión, se la quitamos limpiamente.
    if (_owner != null && !identical(_owner, owner)) {
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {}
    }
    _owner = owner;

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        if (!identical(_owner, owner)) return; // sesión vieja, ignorar
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            onError('El tag escaneado no es compatible con el estándar NDEF');
            return;
          }
          final message = ndef.cachedMessage ?? await ndef.read();
          if (message == null || message.records.isEmpty) {
            onError('El sticker NFC está vacío o no contiene registros');
            return;
          }
          for (final record in message.records) {
            final raw = utf8.decode(record.payload, allowMalformed: true);
            if (raw.contains('{') && raw.contains('}')) {
              final jsonString = raw.substring(
                raw.indexOf('{'),
                raw.lastIndexOf('}') + 1,
              );
              final decoded = json.decode(jsonString);
              if (decoded is Map<String, dynamic> &&
                  decoded.containsKey('id_bus')) {
                onSuccess(decoded);
                return; // sin stopSession: seguimos escuchando
              }
            }
          }
          onError(
            'El sticker NFC no contiene una identificación válida de bus',
          );
        } catch (e) {
          onError('Error al procesar la lectura del chip NFC: $e');
        }
      },
    );
  }

  /// Solo detiene si quien llama es el dueño actual de la sesión.
  static Future<void> stopSession({Object? owner}) async {
    if (owner != null && !identical(_owner, owner)) return;
    _owner = null;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}
