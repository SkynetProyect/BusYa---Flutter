import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/widget/puntos/puntos_eco_chip.dart';

/// Cabecera reutilizable: degradado verde, esquinas inferiores redondeadas y
/// ondas decorativas (guiño al NFC). Funciona en modo claro y oscuro: en
/// oscuro el degradado se profundiza para no encandilar.
class AppTopBar extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Widget a la derecha. Si es null y [showEcoPoints] es true, se muestra
  /// el [PuntosEcoChip].
  final Widget? trailing;

  /// Muestra el medidor de Puntos Eco. Ponlo en false en la propia pantalla
  /// de Puntos Eco (ya tiene el medidor grande) o donde no haga falta.
  final bool showEcoPoints;

  /// Muestra flecha de volver si hay una ruta anterior.
  final bool showBack;

  const AppTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showBack = false,
    this.showEcoPoints = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = isDark
        ? [
            Color.lerp(AppColors.primary, Colors.black, 0.55)!,
            Color.lerp(AppColors.primary, Colors.black, 0.2)!,
          ]
        : [AppColors.primary, AppColors.primaryLight];

    final ring = Colors.white.withValues(alpha: 0.12);
    final canPop = showBack && Navigator.of(context).canPop();
    final right = trailing ?? (showEcoPoints ? const PuntosEcoChip() : null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: -50, top: -60, child: _Ring(220, ring)),
                Positioned(right: -10, top: -20, child: _Ring(140, ring)),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 12, 20, 22),
                    child: Row(
                      children: [
                        if (canPop)
                          IconButton(
                            tooltip: 'Volver',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.82),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (right != null) ...[
                          const SizedBox(width: 12),
                          right,
                        ],
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

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  const _Ring(this.size, this.color);

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    ),
  );
}
