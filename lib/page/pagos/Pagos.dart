import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/pagos/componentes/TopBar.dart'
    show TopBar;

class Pagos extends StatelessWidget {
  const Pagos({super.key});

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
