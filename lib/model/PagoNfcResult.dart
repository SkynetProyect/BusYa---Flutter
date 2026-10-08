// lib/model/PagoNfcResult.dart
enum PagoNfcStatus { success, emergencySuccess, rejected, debtPending, error }

class PagoNfcResult {
  final PagoNfcStatus status;
  final String message;
  final String? transaccionId;

  PagoNfcResult({
    required this.status,
    required this.message,
    this.transaccionId,
  });

  factory PagoNfcResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? '').toUpperCase();
    final status = switch (rawStatus) {
      'SUCCESS' => PagoNfcStatus.success,
      'EMERGENCY_SUCCESS' => PagoNfcStatus.emergencySuccess,
      'REJECTED' => PagoNfcStatus.rejected,
      'DEBT_PENDING' => PagoNfcStatus.debtPending,
      _ => PagoNfcStatus.error,
    };
    return PagoNfcResult(
      status: status,
      message:
          json['message'] as String? ?? 'Respuesta desconocida del servidor',
      transaccionId: json['transactionId'] as String?,
    );
  }

  bool get isApproved =>
      status == PagoNfcStatus.success ||
      status == PagoNfcStatus.emergencySuccess;

  bool get isEmergency => status == PagoNfcStatus.emergencySuccess;

  bool get hasDebtPending => status == PagoNfcStatus.debtPending;
}
