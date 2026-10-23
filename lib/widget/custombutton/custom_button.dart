import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Verde primario del tema
    final greenColor = colors.primary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          // Fondo oscuro (superficie del tema)
          backgroundColor: colors.surface,
          // Texto e íconos en verde
          foregroundColor: greenColor,
          // Borde verde
          side: BorderSide(color: greenColor, width: 1.5),
          disabledBackgroundColor: colors.surface,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: greenColor,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
              ),
      ),
    );
  }
}
