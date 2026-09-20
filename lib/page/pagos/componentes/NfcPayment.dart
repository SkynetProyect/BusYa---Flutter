import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../model/Tarjeta.dart';
import '../../../model/TransaccionNfc.dart';
import '../../../service/nfc_service.dart';
import '../../../service/rest/transaccion_nfc/TransaccionNfcService.dart';
import '../../../widget/custombutton/custom_button.dart';

class NfcPayment extends StatefulWidget {
  final String idCliente;
  final Tarjeta? selectedTarjeta;

  const NfcPayment({super.key, required this.idCliente, this.selectedTarjeta});

  @override
  State<NfcPayment> createState() => _NfcPaymentState();
}

class _NfcPaymentState extends State<NfcPayment> {
  static const darkPurple = Color(0xFF33304E);
  static const greenPrimary = Color(0xFF529471);

  final _transaccionService = TransaccionNfcService();

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
      // 1. Obtener coordenadas de abordaje GPS
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {}

      final int idBus = dataNfc['id_bus'] ?? 1;
      final double montoPasaje = (dataNfc['tarifa'] ?? 3200).toDouble();

      // 2. Crear objeto TransaccionNfc
      final nuevaTransaccion = TransaccionNfc(
        idBilletera: widget.idCliente,
        idBus: idBus,
        monto: montoPasaje,
        sincronizadoOffline: false,
        latitud: position?.latitude,
        longitud: position?.longitude,
      );

      // 3. Persistir en Supabase mediante el servicio
      await _transaccionService.create(nuevaTransaccion);

      if (mounted) {
        _mostrarDialogoExito(montoPasaje);
      }
    } catch (e) {
      if (mounted) _mostrarSnackBar('Error al registrar transacción: $e');
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

  void _mostrarDialogoExito(double monto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: greenPrimary, size: 54),
            SizedBox(height: 8),
            Text('¡Pasaje Pagado!', style: TextStyle(color: darkPurple)),
          ],
        ),
        content: Text(
          'Se debitaron \$${monto.toStringAsFixed(0)} de tu tarjeta ${_tarjetaSeleccionada?.marca} •••• ${_tarjetaSeleccionada?.ultimosCuatroDigitos}.',
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

        // --- Tarjeta de Acción NFC ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBECEF)),
            boxShadow: [
              BoxShadow(
                color: darkPurple.withOpacity(0.05),
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
  if (m.contains('AMEX') || m.contains('AMERICAN'))
    return const Color(0xFF66BB6A);
  if (m.contains('MASTER')) return const Color(0xFFF9A825);
  return _NfcPaymentState.greenPrimary;
}
