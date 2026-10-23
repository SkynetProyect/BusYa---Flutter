import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_assets.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOGO
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                isDark ? AppAssets.logoDark : AppAssets.logoLight,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.directions_bus_rounded,
                    size: 40,
                    color: colorScheme.primary,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // TÍTULO BUSYA
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'bus',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -2.5,
                        height: 1,
                        color: colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'YA',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -3,
                        height: 1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SUBTÍTULO
          Text(
            'Movilidad inteligente · Medellín',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
