import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

class PerfilAccionesCard extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const PerfilAccionesCard({
    super.key,
    required this.onChangePassword,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  Widget _accion({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color == AppColors.error
              ? AppColors.surfaceError
              : AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color == AppColors.error
              ? AppColors.error
              : AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 8),

            _accion(
              icon: Icons.lock_outline,
              title: 'Cambiar contraseña',
              onTap: onChangePassword,
            ),

            const Divider(height: 1, color: AppColors.border),

            _accion(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              onTap: onLogout,
            ),

            const Divider(height: 1, color: AppColors.border),

            _accion(
              icon: Icons.delete_outline,
              title: 'Eliminar cuenta',
              color: AppColors.error,
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
