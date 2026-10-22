// lib/model/NfcUiState.dart
enum NfcUiState {
  idle, // esperando el tap (ondas)
  processing, // llamando al micro (anillo girando)
  success, // pago normal
  emergency, // te prestamos el pasaje
  successWithDebt, // pagó pasaje actual + pasaje de emergencia
  rejected, // gastaste tu pasaje de emergencia
  error, // red, NFC apagado, tag inválido
}
