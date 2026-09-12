import 'package:flutter_application_1/interfaces/RutaFavoritaInterface.dart';

class RutaFavorita implements RutaFavoritaInterface {
  @override
  final int? id;
  @override
  final String? idUsuario;
  @override
  final int? idRuta;
  @override
  final DateTime? createdAt;

  RutaFavorita({this.id, this.idUsuario, this.idRuta, this.createdAt});
}
