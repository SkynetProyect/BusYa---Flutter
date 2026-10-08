import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Usuario.dart';
import 'package:flutter_application_1/service/rest/usuario/UsuarioService.dart';
import 'package:flutter_application_1/core/utils/perfil_validators.dart';
import 'package:flutter_application_1/widget/custombutton/custom_button.dart';
import 'package:flutter_application_1/widget/customtextfield/custom_text_field.dart';

class EditarPerfilPage extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilPage({super.key, required this.usuario});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final UsuarioService _usuarioService = UsuarioService();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _celularController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.usuario.primerNombre,
    );

    _apellidoController = TextEditingController(
      text: widget.usuario.primerApellido,
    );

    _celularController = TextEditingController(
      text: widget.usuario.celular ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _celularController.dispose();

    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final celular = _celularController.text.trim();

    // Validar nombre
    final errorNombre = PerfilValidators.validarNombre(nombre);

    if (errorNombre != null) {
      _showSnackBar(errorNombre);
      return;
    }

    // Validar apellido
    final errorApellido = PerfilValidators.validarApellido(apellido);

    if (errorApellido != null) {
      _showSnackBar(errorApellido);
      return;
    }

    // Validar celular
    final errorCelular = PerfilValidators.validarCelular(celular);

    if (errorCelular != null) {
      _showSnackBar(errorCelular);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _usuarioService.updateProfile(
        id: widget.usuario.id,
        primerNombre: nombre,
        primerApellido: apellido,
        celular: celular,
      );

      if (!mounted) return;

      _showSnackBar('Perfil actualizado correctamente');

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('No se pudieron guardar los cambios. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkPurple = AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: darkPurple, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBECEF)),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Actualiza los datos que deseas modificar de tu perfil.',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(height: 20),

                // NOMBRE
                CustomTextField(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]'),
                    ),
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),

                const SizedBox(height: 16),

                // APELLIDO
                CustomTextField(
                  controller: _apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]'),
                    ),
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),

                const SizedBox(height: 16),

                // CELULAR
                CustomTextField(
                  controller: _celularController,
                  label: 'Celular',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),

                const SizedBox(height: 24),

                // BOTÓN
                CustomButton(
                  text: 'Guardar Cambios',
                  isLoading: _isLoading,
                  onPressed: _guardarCambios,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
