

import 'dart:async';

import 'package:flutter_application_1/interfaces/DataInterface.dart';
import 'package:flutter_application_1/model/Data.dart';

// mi primer patron singleton, que bonito :)

class StreamingService {
  StreamingService._();
  static StreamingService getInstance() => StreamingService._();
  static final _streamController = StreamController<DataInterface>.broadcast();

  void agregar(Data data){
    _streamController.add(data);
  }
  void cerrar(){
    _streamController.close();
  }

  Stream<Object> get mensajes => _streamController.stream;



}