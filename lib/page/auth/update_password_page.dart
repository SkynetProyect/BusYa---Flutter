import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/validators.dart';
import '../../service/rest/auth/auth_repository.dart';
import '../../service/rest/auth/auth_repository_impl.dart.dart';
import '../../widget/custombutton/custom_button.dart';
import '../../widget/customtextfield/custom_text_field.dart';
import '../../widget/passwordstrengthindicator/password_strength_indicator.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passController.removeListener(_onPasswordChanged);
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final newPassword = _passController.text.trim();
    final confirmPassword = _confirmPassController.text.trim();

    if (!Validators.isNotEmpty(newPassword) ||
        !Validators.isNotEmpty(confirmPassword)) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    if (!Validators.isValidPassword(newPassword)) {
      _showSnackBar('La contraseña no cumple con los requisitos de seguridad');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.updateUserPassword(newPassword);
      if (mounted) {
        _showSnackBar('Contraseña actualizada exitosamente');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Ocurrió un error al reestablecer la contraseña');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF33304E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkPurple = Color(0xFF33304E);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Nueva Contraseña',
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
                  'Crea tu nueva clave',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tu nueva contraseña respetando las políticas de seguridad.',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Campo Nueva Contraseña
                CustomTextField(
                  controller: _passController,
                  label: 'Nueva Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                PasswordStrengthIndicator(password: _passController.text),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPassController,
                  label: 'Confirmar Nueva Contraseña',
                  icon: Icons.lock_reset_outlined,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Guardar Contraseña',
                  isLoading: _isLoading,
                  onPressed: _handleUpdatePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
