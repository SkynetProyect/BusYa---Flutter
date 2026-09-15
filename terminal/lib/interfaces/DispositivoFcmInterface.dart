abstract class DispositivoFcmInterface {
  final int? id;
  final String? idUsuario;
  final String fcmToken;
  final String? plataforma;
  final DateTime? updatedAt;

  DispositivoFcmInterface({
    this.id,
    this.idUsuario,
    required this.fcmToken,
    this.plataforma,
    this.updatedAt,
  });
}
