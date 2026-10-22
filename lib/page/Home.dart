import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/service/PasajeEmergenciaState.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/page/inicio/Inicio.dart';
import 'package:flutter_application_1/page/pagos/Pagos.dart';
import 'package:flutter_application_1/page/perfil/Perfil.dart';
import 'package:flutter_application_1/page/rutas/Rutas.dart';
import 'package:flutter_application_1/widget/buttombar/BarraNavegacion.dart';
import 'package:flutter_application_1/page/puntos/puntos_eco_screen.dart';
import 'package:flutter_application_1/page/historial/Historial.dart';

class Application extends StatefulWidget {
  const Application({super.key});
  @override
  State<Application> createState() => _Home();
}

class _Home extends State<Application> {
  var _selectedIndex = 0;
  String? _idCliente;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _idCliente = supabase.auth.currentUser?.id;
    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;
      final nuevoId = authState.session?.user.id;
      if (nuevoId != _idCliente) {
        // Otro usuario o sesión cerrada: se descarta la deuda en memoria.
        PasajeEmergenciaState.instance.reset();
      }
      setState(() => _idCliente = nuevoId);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _idCliente ?? '';
    final hayUsuario = id.isNotEmpty;

    // Cada pestaña se destruye al cambiar, así que el NFC de Pagos
    // solo está activo mientras esa pestaña es la visible.
    final List<Widget> pantalla = [
      Inicio(),
      hayUsuario
          ? Pagos(key: ValueKey('pagos-$id'), idCliente: id)
          : const SizedBox.shrink(),
      Historial(idCliente: id),
      Rutas(),
      Perfil(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton.extended(
          heroTag: 'btnPuntosEco',
          backgroundColor: AppColors.greenDark,
          icon: const Icon(Icons.eco, color: AppColors.green),
          label: const Text(
            'Puntos Eco',
            style: TextStyle(
              color: AppColors.surfaceWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PuntosEcoScreen()),
            );
          },
        ),
      ),
      body: SafeArea(bottom: false, child: pantalla[_selectedIndex]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BarraNavegacion(
          selectedIndex: _selectedIndex,
          callbackfunction: (numero) {
            setState(() => _selectedIndex = numero);
          },
        ),
      ),
    );
  }
}
