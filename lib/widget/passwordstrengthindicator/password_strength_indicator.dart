import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import '../../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    // Verificación de reglas individuales
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]',
    ).hasMatch(password);

    final strength = Validators.getPasswordStrength(password);
    final color = _getColor(strength);
    final label = _getLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // 1. Barra de progreso animada
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: AppColors.neutralLighter,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 2. Checklist interactivo con tachado
        _buildRequirementItem('Mínimo 8 caracteres', hasMinLength),
        _buildRequirementItem(
          'Al menos una letra mayúscula (A-Z)',
          hasUppercase,
        ),
        _buildRequirementItem(
          'Al menos una letra minúscula (a-z)',
          hasLowercase,
        ),
        _buildRequirementItem('Al menos un número (0-9)', hasDigits),
        _buildRequirementItem(
          'Un carácter especial (!@#\$%...)',
          hasSpecialChar,
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppColors.greenDark : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet
                    ? AppColors.textDark
                    : AppColors.textSecondaryMuted,
                decoration: isMet
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double strength) {
    if (strength <= 0.2) return AppColors.error;
    if (strength <= 0.6) return AppColors.warning;
    if (strength <= 0.8) return AppColors.warningLight;
    return AppColors.greenDark;
  }

  String _getLabel(double strength) {
    if (strength == 0.0) return '';
    if (strength <= 0.2) return 'Muy débil';
    if (strength <= 0.6) return 'Media';
    if (strength <= 0.8) return 'Buena';
    return 'Muy fuerte';
  }
}
