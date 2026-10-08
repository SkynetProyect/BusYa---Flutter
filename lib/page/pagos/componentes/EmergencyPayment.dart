import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/service/PaymentProcessorService.dart';
import 'package:flutter_application_1/widget/custombutton/custom_button.dart';

class EmergencyPayment extends StatefulWidget {
  final String idCliente;
  final num monto;
  final Tarjeta? selectedTarjeta;
  final VoidCallback onPagado;

  const EmergencyPayment({
    super.key,
    required this.idCliente,
    required this.monto,
    required this.selectedTarjeta,
    required this.onPagado,
  });

  @override
  State<EmergencyPayment> createState() => _EmergencyPaymentState();
}

class _EmergencyPaymentState extends State<EmergencyPayment> {
  bool _loading = false;
  final _service = PaymentProcessorService();

  Future<void> _pagar() async {
    final tarjeta = widget.selectedTarjeta;
    if (tarjeta == null || tarjeta.id == null) return;

    setState(() => _loading = true);
    try {
      final resp = await _service.pagarEmergencia(
        idCliente: widget.idCliente,
        idTarjeta: tarjeta.id!,
      );

      if (!mounted) return;

      if (resp.ok) {
        widget.onPagado();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarjeta = widget.selectedTarjeta;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBECEF)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emergency, color: AppColors.primary, size: 54),
          const SizedBox(height: 12),
          const Text(
            'Pasaje de emergencia pendiente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tarjeta == null
                ? 'Selecciona una tarjeta para pagar \$${widget.monto}.'
                : 'Se cobrará \$${widget.monto} a ${tarjeta.marca} •••• ${tarjeta.ultimosCuatroDigitos}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Pagar pasaje de emergencia',
            isLoading: _loading,
            onPressed: tarjeta == null ? null : _pagar,
          ),
        ],
      ),
    );
  }
}
