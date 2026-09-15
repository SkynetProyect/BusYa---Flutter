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

  const BarraNavegacion({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFEBECEF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF33304E).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
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
