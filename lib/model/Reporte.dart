class Reporte {
  final int id;
  final String idUsuario;
  final String texto;

  Reporte({required this.id, required this.idUsuario, required this.texto});

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: json["id"],
      idUsuario: json["id_usuario"],
      texto: json["texto"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "id_usuario": idUsuario,
    "texto": texto,
  };
}
