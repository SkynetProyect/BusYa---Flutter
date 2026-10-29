import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/page/inicio/componentes/MapaRutaRequest.dart';
import 'package:flutter_application_1/service/PasajeEmergenciaState.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/page/inicio/Inicio.dart';

import 'package:flutter_application_1/page/pagos/Pagos.dart';
import 'package:flutter_application_1/page/perfil/Perfil.dart';
import 'package:flutter_application_1/page/rutas/Rutas.dart';
import 'package:flutter_application_1/widget/buttombar/BarraNavegacion.dart';
import 'package:flutter_application_1/page/historial/Historial.dart';

class Application extends StatefulWidget {
  const Application({super.key});
  @override
  State<Application> createState() => _Home();
}

class _Home extends State<Application> {
  /// Índice de la pestaña del mapa (Inicio) en la lista de pantallas.
  static const int _indiceMapa = 0;

  var _selectedIndex = _indiceMapa;
  String? _idCliente;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Rutas pide abrir una ruta en el mapa: cambiamos a la pestaña Inicio.
    MapaRutaRequest.irAlMapa = () {
      if (mounted) setState(() => _selectedIndex = _indiceMapa);
    };

    _idCliente = supabase.auth.currentUser?.id;
    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;
      final nuevoId = authState.session?.user.id;
      if (nuevoId != _idCliente) {
        PasajeEmergenciaState.instance.reset();
      }
      setState(() => _idCliente = nuevoId);
    });
  }

  @override
  void dispose() {
    MapaRutaRequest.irAlMapa = null;
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = _idCliente ?? '';
    final hayUsuario = id.isNotEmpty;

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
      backgroundColor: theme.scaffoldBackgroundColor,
      // Usamos un Stack para encimar la barra flotante sobre el contenido
      body: Stack(
        children: [
          // 1. Pantalla visible
          Positioned.fill(child: pantalla[_selectedIndex]),

          // 2. Barra de navegación flotante pegada abajo
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: BarraNavegacion(
                selectedIndex: _selectedIndex,
                callbackfunction: (numero) {
                  setState(() => _selectedIndex = numero);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
