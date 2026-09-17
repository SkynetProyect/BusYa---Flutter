import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/page/historial/Historial.dart';
import 'package:flutter_application_1/page/inicio/Inicio.dart';
import 'package:flutter_application_1/page/pagos/Pagos.dart';
import 'package:flutter_application_1/page/perfil/Perfil.dart';
import 'package:flutter_application_1/page/rutas/Rutas.dart';
import 'package:flutter_application_1/widget/buttombar/BarraNavegacion.dart';

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
    debugPrint('[AUTH DEBUG] Home init idCliente=$_idCliente');
    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;
      debugPrint(
        '[AUTH DEBUG] Home auth update event=${authState.event}, '
        'idCliente=${authState.session?.user.id}',
      );
      setState(() {
        _idCliente = authState.session?.user.id;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[AUTH DEBUG] Home build idCliente=${_idCliente ?? '<null>'}');
    final List<Widget> pantalla = [
      Inicio(),
      Pagos(idCliente: _idCliente ?? ''),
      Rutas(),
      Historial(),
      Perfil(),
    ];

    return Scaffold(
      backgroundColor: Color.fromARGB(248, 179, 174, 174),
      //appBar: TopBar(),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          pantalla[_selectedIndex],
          BarraNavegacion(
            selectedIndex: _selectedIndex,
            callbackfunction: (numero) {
              setState(() {
                _selectedIndex = numero;
              });
              print(_selectedIndex);
            },
          ),
        ],
      ),
    );
  }
}
