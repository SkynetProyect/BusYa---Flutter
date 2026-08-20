import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/inicio/componentes/TopBar.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(),
        Container(
          decoration: BoxDecoration(color: Color.fromARGB(255, 152, 152, 224)),
        ),
      ],
    );
  }
}
