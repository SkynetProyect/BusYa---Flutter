import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Usuario.dart';

class PerfilDatosCard extends StatelessWidget {
  final Usuario usuario;

  const PerfilDatosCard({super.key, required this.usuario});

  Widget _dato({
    required BuildContext context,

    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: colors.primary, size: 21),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 5),
            child: Text(
              'Información personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
          _dato(
            context: context,
            icon: Icons.eco_outlined,
            titulo: 'Puntos Eco',
            valor: '${usuario.puntosEco ?? 0} pts',
          ),
          Divider(height: 1, color: theme.dividerColor),
          _dato(
            context: context,
            icon: Icons.badge_outlined,
            titulo: 'Documento',
            valor: usuario.numeroDocumento,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _dato(
            context: context,
            icon: Icons.phone_outlined,
            titulo: 'Celular',
            valor: usuario.celular ?? 'No registrado',
          ),
        ],
      ),
    );
  }
}
