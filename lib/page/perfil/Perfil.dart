import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Usuario.dart';
import 'package:flutter_application_1/page/perfil/componentes/TopBar.dart'
    show TopBar;
import 'package:flutter_application_1/page/perfil/componentes/perfil_header_card.dart';
import 'package:flutter_application_1/page/perfil/componentes/perfil_datos_card.dart';
import 'package:flutter_application_1/page/perfil/componentes/perfil_acciones_card.dart';
import 'package:flutter_application_1/service/rest/usuario/UsuarioService.dart';
import 'package:flutter_application_1/page/perfil/EditarPerfilPage.dart';
import 'package:flutter_application_1/page/perfil/CambiarPassword.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<Usuario> _usuarioFuture;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  void _cargarUsuario() {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _usuarioFuture = Future.error(Exception('No hay un usuario autenticado'));
    } else {
      _usuarioFuture = _usuarioService.getById(user.id);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();
      // TODO: Redirigir a la pantalla de login
    }
  }

  Future<void> _eliminarCuenta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es irreversible. ¿Seguro que deseas eliminar tu cuenta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implementar lógica para eliminar cuenta
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: FutureBuilder<Usuario>(
            future: _usuarioFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'No se pudo cargar el perfil',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final usuario = snapshot.data;

              if (usuario == null) {
                return const Center(child: Text('Usuario no encontrado'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PerfilHeaderCard(
                      usuario: usuario,
                      onEditPressed: () async {
                        final actualizado = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditarPerfilPage(usuario: usuario),
                          ),
                        );

                        if (actualizado == true && mounted) {
                          setState(() {
                            _cargarUsuario();
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    PerfilDatosCard(usuario: usuario),

                    const SizedBox(height: 20),

                    PerfilAccionesCard(
                      onChangePassword: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CambiarPasswordPage(),
                          ),
                        );
                      },
                      onLogout: _cerrarSesion,
                      onDeleteAccount: _eliminarCuenta,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
