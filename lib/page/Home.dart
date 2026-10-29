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
import 'package:flutter_application_1/features/voice/application/voice_controller.dart';
import 'package:flutter_application_1/features/voice/domain/voice_intent.dart';
import 'package:flutter_application_1/features/voice/presentation/voice_button.dart';
import 'package:flutter_application_1/features/voice/presentation/voice_assistant_panel.dart';
import 'package:flutter_application_1/features/voice/presentation/voice_layout.dart';
import 'package:flutter_application_1/features/voice/voice_module.dart';
import 'package:flutter_application_1/features/voice/application/period_range.dart';
import 'package:flutter_application_1/widget/gasto/ResumenGastoSheet.dart';

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
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();

    // Rutas pide abrir una ruta en el mapa: cambiamos a la pestaña Inicio.
    MapaRutaRequest.irAlMapa = () {
      if (mounted) setState(() => _selectedIndex = _indiceMapa);
    };

    _voiceController = createVoiceController();
    unawaited(_voiceController.initialize());
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
    _voiceController.dispose();
    super.dispose();
  }

  bool get _hayUsuario => (_idCliente ?? '').isNotEmpty;

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _onVoiceIntent(VoiceIntent intent) {
    if (!mounted) return;

    switch (intent) {
      case NavigateIntent(destination: final destination):
        final requiereUsuario =
            destination == VoiceDestination.pagar ||
            destination == VoiceDestination.tarjetas ||
            destination == VoiceDestination.historial;
        if (requiereUsuario && !_hayUsuario) {
          _avisar('Inicia sesión primero.');
          return;
        }

        final index = switch (destination) {
          VoiceDestination.inicio => 0,
          VoiceDestination.pagar => 1,
          VoiceDestination.tarjetas => 1,
          VoiceDestination.historial => 2,
          VoiceDestination.rutas => 3,
          VoiceDestination.perfil => 4,
        };
        setState(() => _selectedIndex = index);

      case AnswerIntent(message: final message):
        _avisar(message);

      case UnknownIntent():
        _avisar('No te entendí. Prueba con "pagar pasaje" o "ver historial".');

      case SpendingQueryIntent(period: final period):
        _mostrarResumenGasto(period);
    }
  }

  void _mostrarResumenGasto(SpendingPeriod period) {
    if (!_hayUsuario) {
      _avisar('Inicia sesión primero.');
      return;
    }

    final rango = rangeForPeriod(period, DateTime.now());
    unawaited(
      ResumenGastoSheet.show(
        context,
        titulo: rango.titulo,
        desde: rango.desde,
        hasta: rango.hasta,
        onVerHistorial: () {
          if (mounted) setState(() => _selectedIndex = 2);
        },
        onLoaded: (resumen) {
          // TODO(voz): decir resumen.textoHablado(rango.frase) con el speaker.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = _idCliente ?? '';
    final hayUsuario = id.isNotEmpty;
    final bottomNavigationOffset =
        kVoiceNavigationHeight + MediaQuery.of(context).padding.bottom;

    final List<Widget> pantalla = [
      Inicio(voiceController: _voiceController),
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

          // 3. Panel del asistente (solo fuera de la pestaña Pagos)
          if (_selectedIndex != 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomNavigationOffset,
              child: VoiceAssistantPanel(controller: _voiceController),
            ),

          // 4. Botón de voz (solo fuera de la pestaña Pagos)
          if (_selectedIndex != 1)
            Positioned(
              right: kVoiceHorizontalInset,
              bottom: bottomNavigationOffset + kVoiceBottomInset,
              child: VoiceButton(
                controller: _voiceController,
                onIntent: _onVoiceIntent,
              ),
            ),
        ],
      ),
    );
  }
}
