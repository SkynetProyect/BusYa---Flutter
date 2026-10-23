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
    required BuildContext context,

    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final actionColor = isDestructive ? AppColors.error : colors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withValues(alpha: 0.10)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: actionColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : colors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuenta',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _accion(
            context: context,
            icon: Icons.lock_outline_rounded,
            title: 'Cambiar contraseña',
            onTap: onChangePassword,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _accion(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            onTap: onLogout,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _accion(
            context: context,
            icon: Icons.delete_outline_rounded,
            title: 'Eliminar cuenta',
            onTap: onDeleteAccount,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
