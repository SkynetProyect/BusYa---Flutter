import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppTopBar({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        // Sombra suave para dar profundidad en fondo oscuro
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: colorScheme.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
