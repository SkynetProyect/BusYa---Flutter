import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/perfil/componentes/TopBar.dart'
    show TopBar;

class Perfil extends StatelessWidget {
  const Perfil({super.key});

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
