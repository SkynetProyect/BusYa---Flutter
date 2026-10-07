import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Usuario.dart';

class PerfilDatosCard extends StatelessWidget {
  final Usuario usuario;

  const PerfilDatosCard({super.key, required this.usuario});

  Widget _dato({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Información personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 4),

          _dato(
            icon: Icons.eco_outlined,
            titulo: 'Puntos Eco',
            valor: '${usuario.puntosEco ?? 0} pts',
          ),

          const Divider(height: 1, color: Color(0xFFEBECEF)),

          _dato(
            icon: Icons.badge_outlined,
            titulo: 'Documento',
            valor: usuario.numeroDocumento,
          ),

          const Divider(height: 1, color: Color(0xFFEBECEF)),

          _dato(
            icon: Icons.phone_outlined,
            titulo: 'Celular',
            valor: usuario.celular ?? 'No registrado',
          ),
        ],
      ),
    );
  }
}
