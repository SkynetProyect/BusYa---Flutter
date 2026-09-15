import 'package:flutter_application_1/interfaces/ParaderoFavoritoInterface.dart';

class ParaderoFavorito implements ParaderoFavoritoInterface {
  @override
  final int? id;
  @override
  final String? idUsuario;
  @override
  final int? idParadero;
  @override
  final DateTime? createdAt;

  ParaderoFavorito({this.id, this.idUsuario, this.idParadero, this.createdAt});
}
