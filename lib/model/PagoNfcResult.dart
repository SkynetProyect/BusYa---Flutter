enum PagoNfcStatus {
  success,
  emergencySuccess,
  successWithEmergency,
  rejected,
  error,
}

class PagoNfcResult {
  final PagoNfcStatus status;
  final String message;
  final String? transaccionId;
  final double? montoCobrado;
  final bool? tieneDeudaPendiente;
  final double? montoPendiente;

  PagoNfcResult({
    required this.status,
    required this.message,
    this.transaccionId,
    this.montoCobrado,
    this.tieneDeudaPendiente,
    this.montoPendiente,
  });

  factory PagoNfcResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? '').toUpperCase();
    final status = switch (rawStatus) {
      'SUCCESS' => PagoNfcStatus.success,
      'EMERGENCY_SUCCESS' => PagoNfcStatus.emergencySuccess,
      'PAID_WITH_EMERGENCY' => PagoNfcStatus.successWithEmergency,
      'REJECTED' => PagoNfcStatus.rejected,
      _ => PagoNfcStatus.error,
    };
    return PagoNfcResult(
      status: status,
      message:
          json['message'] as String? ?? 'Respuesta desconocida del servidor',
      transaccionId: json['transactionId'] as String?,
      montoCobrado: (json['montoCobrado'] as num?)?.toDouble(),
      tieneDeudaPendiente: json['tieneDeudaPendiente'] as bool?,
      montoPendiente: (json['montoPendiente'] as num?)?.toDouble(),
    );
  }

  bool get isApproved =>
      status == PagoNfcStatus.success ||
      status == PagoNfcStatus.emergencySuccess ||
      status == PagoNfcStatus.successWithEmergency;

  bool get isEmergency => status == PagoNfcStatus.emergencySuccess;
}
