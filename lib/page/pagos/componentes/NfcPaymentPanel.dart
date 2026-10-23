import 'package:flutter/material.dart';
import '../../../service/NfcPaymentController.dart';
import '../../../widget/nfc/wallet_nfc_indicator.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/model/NfcUiState.dart';

class NfcPaymentPanel extends StatelessWidget {
  const NfcPaymentPanel({super.key, required this.controller});
  final NfcPaymentController controller;

  (String, String) _textos() {
    final c = controller;
    if (!c.nfcActivo) {
      return ('NFC desactivado', 'Actívalo para pagar tus pasajes');
    }
    final card = c.tarjeta == null
        ? 'Selecciona una tarjeta'
        : '${c.tarjeta!.marca} •••• ${c.tarjeta!.ultimosCuatroDigitos}';
    return switch (c.state) {
      NfcUiState.idle => ('Acerca tu teléfono al bus', 'Pagarás con $card'),
      NfcUiState.processing => ('Procesando pago…', card),
      NfcUiState.success => ('¡Pago exitoso!', '${cop(c.monto ?? 0)} · $card'),
      NfcUiState.emergency => (
        'Pasaje de emergencia',
        'No tenías saldo, te lo prestamos. Se cobrará en tu próximo pago.',
      ),
      NfcUiState.successWithDebt => (
        '¡Pago exitoso!',
        '${cop(c.monto ?? 0)} · incluye tu pasaje de emergencia pendiente',
      ),
      NfcUiState.rejected => (
        'Pago rechazado',
        'Gastaste tu pasaje de emergencia y el saldo no alcanza',
      ),
      NfcUiState.error => ('No se pudo pagar', c.message),
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, __) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final (titulo, detalle) = _textos();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: controller.nfcActivo ? 1 : 0.35,
              child: WalletNfcIndicator(state: controller.state),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey('${controller.nfcActivo}-${controller.state}'),
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
