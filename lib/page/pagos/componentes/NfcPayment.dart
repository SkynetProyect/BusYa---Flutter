import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import '../../../model/Tarjeta.dart';
import '../../../model/PagoNfcResult.dart';
import '../../../service/nfc_service.dart';
import '../../../service/PaymentProcessorService.dart';
import '../../../widget/custombutton/custom_button.dart';
import '../../../service/determinePosition.dart';

class NfcPayment extends StatefulWidget {
  final String idCliente;
  final Tarjeta? selectedTarjeta;

  const NfcPayment({super.key, required this.idCliente, this.selectedTarjeta});

  @override
  State<NfcPayment> createState() => _NfcPaymentState();
}

class _NfcPaymentState extends State<NfcPayment> {
  static const darkPurple = AppColors.primary;
  static const greenPrimary = AppColors.primary;

  final _paymentService = PaymentProcessorService();

  Tarjeta? _tarjetaSeleccionada;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tarjetaSeleccionada = widget.selectedTarjeta;
  }

  @override
  void didUpdateWidget(covariant NfcPayment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTarjeta?.id != widget.selectedTarjeta?.id) {
      _tarjetaSeleccionada = widget.selectedTarjeta;
    }
  }

  void _iniciarPagoNfc() async {
    if (_tarjetaSeleccionada == null) {
      _mostrarSnackBar('Por favor selecciona una tarjeta para pagar');
      return;
    }

    setState(() => _isProcessing = true);
    _mostrarBottomSheetEscaneo();

    await NfcService.startSession(
      onSuccess: (dataNfc) async {
        if (mounted) Navigator.pop(context); // Cierra BottomSheet
        await _procesarCobro(dataNfc);
      },
      onError: (error) {
        if (mounted) {
          Navigator.pop(context);
          setState(() => _isProcessing = false);
          _mostrarSnackBar(error);
        }
      },
    );
  }

  Future<void> _procesarCobro(Map<String, dynamic> dataNfc) async {
    try {
      // Pide permisos si hace falta; si falla, el pago sigue sin ubicación
      Position? position;
      try {
        position = await determinePosition();
      } catch (_) {}

      final resultado = await _paymentService.procesarPagoNfc(
        dataNfc: dataNfc,
        tarjetaSeleccionada: _tarjetaSeleccionada!,
        idCliente: widget.idCliente,
        latitud: position?.latitude,
        longitud: position?.longitude,
      );

      if (!mounted) return;

      final double montoPasaje = (dataNfc['tarifa'] ?? 3207).toDouble();

      switch (resultado.status) {
        case PagoNfcStatus.success:
          _mostrarDialogoExito(montoPasaje, esEmergencia: false);
          break;
        case PagoNfcStatus.emergencySuccess:
          _mostrarDialogoExito(montoPasaje, esEmergencia: true);
          break;
        case PagoNfcStatus.rejected:
        case PagoNfcStatus.error:
          _mostrarSnackBar(resultado.message);
          break;
      }
    } catch (e) {
      if (mounted) _mostrarSnackBar('Error al procesar el pago: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _mostrarBottomSheetEscaneo() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 280,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nfc_rounded, size: 64, color: greenPrimary),
            const SizedBox(height: 16),
            const Text(
              'Acerque su teléfono al bus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mantenga el teléfono cerca del sticker NFC',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                NfcService.stopSession();
                Navigator.pop(context);
                setState(() => _isProcessing = false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoExito(double monto, {required bool esEmergencia}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              esEmergencia ? Icons.emergency : Icons.check_circle,
              color: greenPrimary,
              size: 54,
            ),
            const SizedBox(height: 8),
            Text(
              esEmergencia ? '¡Pasaje de emergencia usado!' : '¡Pasaje Pagado!',
              style: const TextStyle(color: darkPurple),
            ),
          ],
        ),
        content: Text(
          esEmergencia
              ? 'No tenías saldo, así que se usó tu único pasaje de emergencia disponible por \$${monto.toStringAsFixed(0)}.'
              : 'Se debitaron \$${monto.toStringAsFixed(0)} de tu tarjeta ${_tarjetaSeleccionada?.marca} •••• ${_tarjetaSeleccionada?.ultimosCuatroDigitos}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar', style: TextStyle(color: greenPrimary)),
          ),
        ],
      ),
    );
  }

  void _mostrarSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: darkPurple));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Resumen de tarjeta seleccionada (sin dropdown) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBECEF)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.credit_card,
                color: _brandAccentColor(widget.selectedTarjeta?.marca),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.selectedTarjeta != null
                      ? '${widget.selectedTarjeta!.marca} •••• ${widget.selectedTarjeta!.ultimosCuatroDigitos}'
                      : 'No tienes tarjetas registradas',
                  style: const TextStyle(
                    color: darkPurple,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBECEF)),
            boxShadow: [
              BoxShadow(
                color: darkPurple.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.contactless_outlined,
                color: greenPrimary,
                size: 54,
              ),
              const SizedBox(height: 12),
              const Text(
                'Pago sin contacto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Acerca el teléfono al sticker NFC del bus para debitar tu pasaje automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Pagar con NFC',
                isLoading: _isProcessing,
                onPressed: _iniciarPagoNfc,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _brandAccentColor(String? marca) {
  final m = (marca ?? '').trim().toUpperCase();
  if (m.contains('VISA')) return const Color(0xFF1E5AB6);
  if (m.contains('AMEX') || m.contains('AMERICAN')) {
    return const Color(0xFF66BB6A);
  }
  if (m.contains('MASTER')) return const Color(0xFFF9A825);
  return AppColors.primary;
}
