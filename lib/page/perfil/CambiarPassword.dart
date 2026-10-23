import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/validators.dart';
import '../../service/rest/auth/auth_repository.dart';
import '../../service/rest/auth/auth_repository_impl.dart.dart';
import '../../widget/custombutton/custom_button.dart';
import '../../widget/customtextfield/custom_text_field.dart';

class CambiarPasswordPage extends StatefulWidget {
  const CambiarPasswordPage({super.key});

  @override
  State<CambiarPasswordPage> createState() => _CambiarPasswordPageState();
}

class _CambiarPasswordPageState extends State<CambiarPasswordPage> {
  final AuthRepository _authRepository = AuthRepositoryImpl();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!Validators.isNotEmpty(password)) {
      _showSnackBar('Por favor ingresa una nueva contraseña');
      return;
    }

    if (!Validators.isValidPassword(password)) {
      _showSnackBar('La contraseña no cumple con todos los requisitos.');
      return;
    }

    if (!Validators.isNotEmpty(confirmPassword)) {
      _showSnackBar('Por favor confirma tu nueva contraseña');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.updateUserPassword(password);

      if (mounted) {
        _showSnackBar('Contraseña actualizada correctamente');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Ocurrió un error al cambiar la contraseña.');
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPasswordRequirement({
    required bool fulfilled,
    required String text,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            fulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: fulfilled ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: fulfilled ? colors.primary : colors.onSurfaceVariant,
              fontWeight: fulfilled ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final password = _passwordController.text;

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(
      r'[!@#$%^&*(),.?":{}|<>\_\-+=/\\[\]~`]',
    ).hasMatch(password);

    final strength = Validators.getPasswordStrength(password);

    String strengthText;
    if (strength <= 0.4) {
      strengthText = 'Débil';
    } else if (strength < 1.0) {
      strengthText = 'Media';
    } else {
      strengthText = 'Fuerte';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seguridad de la contraseña',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: strengthText == 'Fuerte'
                      ? colors.primary
                      : strengthText == 'Media'
                      ? colors.tertiary
                      : colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Barra de fortaleza
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 7,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                strengthText == 'Fuerte'
                    ? colors.primary
                    : strengthText == 'Media'
                    ? colors.tertiary
                    : colors.error,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _buildPasswordRequirement(
            fulfilled: hasMinLength,
            text: 'Mínimo 8 caracteres',
          ),
          _buildPasswordRequirement(
            fulfilled: hasUppercase,
            text: 'Una letra mayúscula',
          ),
          _buildPasswordRequirement(
            fulfilled: hasLowercase,
            text: 'Una letra minúscula',
          ),
          _buildPasswordRequirement(fulfilled: hasNumber, text: 'Un número'),
          _buildPasswordRequirement(
            fulfilled: hasSpecial,
            text: 'Un carácter especial',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cambiar contraseña',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva contraseña',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa y confirma tu nueva contraseña.',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _passwordController,
                  label: 'Nueva contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                _buildPasswordStrength(),

                const SizedBox(height: 18),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
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
                  text: 'Cambiar contraseña',
                  isLoading: _isLoading,
                  onPressed: _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
