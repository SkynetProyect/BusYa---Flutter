import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/PasajeEmergenciaState.dart';
import 'package:flutter_application_1/core/format.dart';

class EmergencyDebtBanner extends StatelessWidget {
  const EmergencyDebtBanner({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PasajeEmergenciaState.instance,
    builder: (_, __) {
      final colors = Theme.of(context).colorScheme;
      final monto = PasajeEmergenciaState.instance.monto;
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: monto == null
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Debes tu pasaje de emergencia (${cop(monto)}). Se cobrará junto con tu próximo pasaje.',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    },
  );
}
