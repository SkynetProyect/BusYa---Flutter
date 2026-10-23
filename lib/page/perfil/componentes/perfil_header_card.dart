import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Usuario.dart';

class PerfilHeaderCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEditPressed;

  const PerfilHeaderCard({
    super.key,
    required this.usuario,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final email = supabase.auth.currentUser?.email ?? 'No registrado';
    final nombreCompleto = '${usuario.primerNombre} ${usuario.primerApellido}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: colors.primary.withValues(alpha: 0.10),
            child: Icon(
              Icons.person_outline_rounded,
              size: 42,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            nombreCompleto,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text('Editar perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.55)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
