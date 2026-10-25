import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Usuario.dart';
import 'package:flutter_application_1/page/perfil/componentes/ReportarErrorDialog.dart'
    show showReportarErrorDialog;
import 'package:flutter_application_1/widget/app_top_bar.dart';
import 'package:flutter_application_1/page/perfil/componentes/perfil_header_card.dart';
import 'package:flutter_application_1/page/perfil/componentes/perfil_datos_card.dart';
import 'package:flutter_application_1/page/perfil/componentes/perfil_acciones_card.dart';
import 'package:flutter_application_1/service/rest/usuario/UsuarioService.dart';
import 'package:flutter_application_1/page/perfil/EditarPerfilPage.dart';
import 'package:flutter_application_1/page/perfil/CambiarPassword.dart';
import 'package:flutter_application_1/page/perfil/componentes/apariencia_card.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: colorScheme.error),
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
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Text('Eliminar', style: TextStyle(color: colorScheme.error)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          const AppTopBar(
            title: 'Perfil',
            subtitle: 'Gestiona tu información personal',
          ),
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PerfilHeaderCard(
                        usuario: usuario,
                        onEditPressed: () async {
                          final actualizado = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditarPerfilPage(usuario: usuario),
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

                      const AparienciaCard(),

                      const SizedBox(height: 12),

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
                      const SizedBox(height: 20),

                      // Botón para reportar errores de la app estilizado
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          // CORRECCIÓN: el diálogo ahora exige el id del usuario.
                          onPressed: () => showReportarErrorDialog(
                            context,
                            idUsuario: usuario.id,
                          ),
                          icon: const Icon(Icons.bug_report_outlined, size: 19),
                          label: const Text('Reportar error'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            backgroundColor: colorScheme.surface,
                            side: BorderSide(
                              color: colorScheme.primary.withValues(
                                alpha: 0.55,
                              ),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
