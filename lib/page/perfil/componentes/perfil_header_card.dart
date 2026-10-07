import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Usuario.dart';

class PerfilHeaderCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEditPressed;

  const PerfilHeaderCard({
    super.key,
    required this.usuario,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? 'No registrado';
    final nombreCompleto = '${usuario.primerNombre} ${usuario.primerApellido}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEF)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFFF0EDF8),
            child: Icon(
              Icons.person_outline,
              size: 42,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text(
                'Editar perfil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
