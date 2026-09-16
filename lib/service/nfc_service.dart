class NfcService {
  static Future<bool> isNfcAvailable() async {
    return false;
  }

  static Future<void> startSession({
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onError,
  }) async {
    onError('El pago NFC está temporalmente deshabilitado');
  }

  static Future<void> stopSession() async {}
}
