import 'package:flutter/material.dart';

import 'package:flutter_application_1/page/historial/Historial.dart';
import 'package:flutter_application_1/page/inicio/Inicio.dart';
import 'package:flutter_application_1/page/pagos/Pagos.dart';
import 'package:flutter_application_1/page/perfil/Perfil.dart';
import 'package:flutter_application_1/page/rutas/Rutas.dart';
import 'package:flutter_application_1/widget/buttombar/BarraNavegacion.dart';

class Application extends StatefulWidget {
  const Application({super.key});
  @override
  State<Application> createState() => _Home();
}

class _Home extends State<Application> {
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pantalla = [
      Inicio(),
      Pagos(),
      Rutas(),
      Historial(),
      Perfil(),
    ];

    return Scaffold(
      backgroundColor: Color.fromARGB(248, 179, 174, 174),
      //appBar: TopBar(),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          pantalla[_selectedIndex],
          BarraNavegacion(
            selectedIndex: _selectedIndex,
            callbackfunction: (numero) {
              setState(() {
                _selectedIndex = numero;
              });
              print(_selectedIndex);
            },
          ),
        ],
      ),
    );
  }
}
