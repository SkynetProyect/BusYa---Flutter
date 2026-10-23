import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/buttombar/IconoInicio.dart'
    show IconoInicio;
import 'package:flutter_application_1/widget/buttombar/IconoPago.dart'
    show IconoPago;
import 'package:flutter_application_1/widget/buttombar/IconoPerfil.dart'
    show IconoPerfil;
import 'package:flutter_application_1/widget/buttombar/IconoHistorial.dart'
    show IconoHistorial;
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
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final surfaceColor = theme.colorScheme.surface;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            // Degradado dinámico basado en la superficie del tema actual (claro/oscuro)
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surfaceColor.withValues(alpha: 0.65),
                surfaceColor.withValues(alpha: 0.88),
              ],
            ),
            // Borde superior usando el dividerColor del Theme
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: 60,
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
        ),
      ),
    );
  }
}
