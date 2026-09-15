import 'package:flutter/material.dart';
import 'dart:ui'; // <-- aquí vive ImageFilter

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5), // bright top/left edge
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 223, 124, 59), // lighter corner
            const Color.fromARGB(255, 25, 27, 150), // darker corner
          ],
        ),
      ),
      child: AppBar(
        title: const Text(
          "Listos en Paz o Emergencia",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(30, 255, 255, 255),
      ),
    );
  }
}
