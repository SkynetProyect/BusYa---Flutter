import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                    children: [
                      TextSpan(text: 'bus', style: TextStyle(color: AppColors.greenOnPrimary)),
                      TextSpan(text: 'YA', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Rutas", // <---------------------------------------------------  TEXTO 2
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Comañias con rutas disponibles", // <---------------------------------------------------  TEXTO 3
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Botón circular con ícono a la derecha
        ],
      ),
    );
  }
}
