import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/buttombar/IconoHistorial.dart'
    show IconoHistorial;
import 'package:flutter_application_1/widget/buttombar/IconoInicio.dart'
    show IconoInicio;
import 'package:flutter_application_1/widget/buttombar/IconoPago.dart'
    show IconoPago;
import 'package:flutter_application_1/widget/buttombar/IconoPerfil.dart'
    show IconoPerfil;
import 'package:flutter_application_1/widget/buttombar/IconoRuta.dart'
    show IconoRuta;

class BarraNavegacion extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;
  static const Color colorleft = Color.fromARGB(255, 59, 158, 223);
  static const Color colorright = Color.fromARGB(255, 54, 212, 94);

  const BarraNavegacion({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      margin: EdgeInsets.only(bottom: 30),
      child: Container(
        width: MediaQuery.sizeOf(context).width - 24,
        constraints: const BoxConstraints(maxWidth: 430),
        height: 50,
        decoration: BoxDecoration(
          color: const Color.fromARGB(
            255,
            230,
            224,
            224,
          ).withValues(alpha: 0.5), // semi-transparent fill
          borderRadius: BorderRadiusGeometry.circular(100),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6), // bright top/left edge
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorleft, colorright],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconoInicio(
              selectedIndex: selectedIndex,
              callbackfunction: callbackfunction,
            ),
            IconoPago(
              selectedIndex: selectedIndex,
              callbackfunction: callbackfunction,
            ),
            IconoRuta(
              selectedIndex: selectedIndex,
              callbackfunction: callbackfunction,
            ),
            IconoHistorial(
              selectedIndex: selectedIndex,
              callbackfunction: callbackfunction,
            ),
            IconoPerfil(
              selectedIndex: selectedIndex,
              callbackfunction: callbackfunction,
            ),
          ],
        ),
      ),
    );
  }
}
