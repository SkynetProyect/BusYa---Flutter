import 'package:flutter_application_1/interfaces/DispositivoFcmInterface.dart';

class DispositivoFcm implements DispositivoFcmInterface {
  @override
  final int? id;
  @override
  final String? idUsuario;
  @override
  final String fcmToken;
  @override
  final String? plataforma;
  @override
  final DateTime? updatedAt;

  DispositivoFcm({
    this.id,
    this.idUsuario,
    required this.fcmToken,
    this.plataforma,
    this.updatedAt,
  });
}
