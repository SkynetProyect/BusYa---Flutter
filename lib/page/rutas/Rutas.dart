import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/rutas/componentes/TopBar.dart'
    show TopBar;

class Rutas extends StatelessWidget {
  const Rutas({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(),
        Container(
          decoration: BoxDecoration(color: Color.fromARGB(255, 191, 191, 194)),
        ),
      ],
    );
  }
}
