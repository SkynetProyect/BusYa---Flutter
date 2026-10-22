import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

// <-- aquí vive ImageFilter

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.8),
        border: Border.all(
          color: AppColors.surfaceWhite.withValues(
            alpha: 0.5,
          ), // bright top/left edge
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.topBarHighlight, // lighter corner
            AppColors.topBarDeep, // darker corner
          ],
        ),
      ),
      child: AppBar(
        title: const Text(
          "Listos en Paz o Emergencia",
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.overlayWhiteSubtle,
      ),
    );
  }
}
