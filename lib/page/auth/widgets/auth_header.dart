import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF11192D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'lib/assets/images/logo_busya.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RUTÉATE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 4),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1),
              children: [
                TextSpan(text: 'bus', style: TextStyle(color: AppColors.green)),
                TextSpan(text: 'YA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Movilidad inteligente · Medellín',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
