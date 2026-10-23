import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme_controller.dart';

class AparienciaCard extends StatelessWidget {
  const AparienciaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        final selectedMode = themeController.themeMode;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accesibilidad y apariencia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Personaliza la apariencia de BusYA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Tema de la aplicación',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _OpcionTema(
                      label: 'Sistema',
                      icon: Icons.settings_suggest_rounded,
                      selected: selectedMode == ThemeMode.system,
                      onTap: () =>
                          themeController.setThemeMode(ThemeMode.system),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OpcionTema(
                      label: 'Claro',
                      icon: Icons.wb_sunny_rounded,
                      selected: selectedMode == ThemeMode.light,
                      onTap: () =>
                          themeController.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OpcionTema(
                      label: 'Oscuro',
                      icon: Icons.nightlight_round,
                      selected: selectedMode == ThemeMode.dark,
                      onTap: () => themeController.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.10)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : theme.dividerColor.withValues(alpha: 0.7),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 15,
                color: selected
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
