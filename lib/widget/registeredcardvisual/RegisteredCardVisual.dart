import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';

class RegisteredCardVisual extends StatelessWidget {
  final Tarjeta tarjeta;
  final bool selected;
  final VoidCallback? onDelete;

  const RegisteredCardVisual({
    super.key,
    required this.tarjeta,
    this.selected = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _brandGradientFor(tarjeta.marca);
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withValues(alpha: selected ? 0.35 : 0.15),
            blurRadius: selected ? 14 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tarjeta.marca.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.contactless, color: Colors.white70, size: 28),
            ],
          ),
          Text(
            '•••• •••• •••• ${tarjeta.ultimosCuatroDigitos}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TITULAR',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      tarjeta.nombreTitular,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXP',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  Text(
                    tarjeta.fechaVencimiento,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: tarjeta.id == null
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : Colors.redAccent,
                  ),
                  tooltip: 'Eliminar tarjeta',
                  onPressed: tarjeta.id == null ? null : onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Color> _brandGradientFor(String marca) {
  final m = marca.trim().toUpperCase();
  if (m.contains('VISA')) {
    return const [Color(0xFF0A3D91), Color(0xFF1E5AB6)];
  }
  if (m.contains('AMEX') || m.contains('AMERICAN')) {
    return const [Color(0xFF66BB6A), Color(0xFF9CCC65)];
  }
  if (m.contains('MASTER')) {
    return const [Color(0xFFF9A825), Color(0xFFFBC02D)];
  }
  return const [AppColors.primary, AppColors.primary];
}
