import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/rest/auth/auth_repository.dart';
import '../../service/rest/auth/auth_repository_impl.dart.dart';
import 'register_page.dart';
import 'widgets/auth_header.dart';
import '../../widget/custombutton/custom_button.dart';
import '../../widget/customtextfield/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Error de conexión al iniciar sesión');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const AuthHeader(),
                const SizedBox(height: 32),
                Container(
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
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF33304E),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Ingresar',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                            color: Color(0xFF529471),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
