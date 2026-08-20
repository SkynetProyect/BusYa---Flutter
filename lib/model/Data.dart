
import 'package:flutter_application_1/interfaces/DataInterface.dart';

class Data implements DataInterface{
  
  @override
  final int codigo;
  @override
  final String string;
  @override
  final Object? datos;

  Data({
    required this.datos,
    required this.codigo,
    required this.string
  });
  
}