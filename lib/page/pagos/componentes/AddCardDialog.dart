import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/service/rest/tarjeta/TarjetaService.dart';

/// Muestra el popup para registrar una nueva tarjeta.
/// Devuelve la Tarjeta creada si tuvo éxito, o null si se canceló/falló.
Future<Tarjeta?> showAddCardDialog(
  BuildContext context, {
  required String idCliente,
}) {
  return showDialog<Tarjeta>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddCardDialog(idCliente: idCliente),
  );
}

class AddCardDialog extends StatefulWidget {
  final String idCliente;
  const AddCardDialog({super.key, required this.idCliente});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  static const green = Color(0xFF1E8A5F);

  final _formKey = GlobalKey<FormState>();
  final _tarjetaService = TarjetaService();

  final _nombreController = TextEditingController();
  final _numeroController = TextEditingController();
  final _vencimientoController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Enforce digits-only even on paste/IME: strip non-digits immediately
    _numeroController.addListener(_enforceDigitsInNumber);
  }

  void _enforceDigitsInNumber() {
    final text = _numeroController.text;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (text != digits) {
      _numeroController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    _vencimientoController.dispose();
    super.dispose();
  }

  String _detectMarca(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    // American Express: 34 or 37 (length typically 15)
    if (digits.startsWith('34') || digits.startsWith('37'))
      return 'American Express';
    // Mastercard: 51-55 or 2221-2720
    if (digits.length >= 2) {
      final first2 = int.tryParse(digits.substring(0, 2));
      if (first2 != null && first2 >= 51 && first2 <= 55) return 'Mastercard';
    }
    if (digits.length >= 4) {
      final first4 = int.tryParse(digits.substring(0, 4));
      if (first4 != null && first4 >= 2221 && first4 <= 2720)
        return 'Mastercard';
    }
    // Visa: starts with 4 (length typically 13, 16, or 19)
    if (digits.startsWith('4')) return 'Visa';
    return 'Desconocida';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    debugPrint(
      '[CARD DEBUG] submit widget.idCliente=${widget.idCliente}, '
      'currentUserId=${supabase.auth.currentUser?.id}, '
      'userRole=${supabase.auth.currentUser?.role}',
    );

    final rawNumber = _numeroController.text.trim();
    final onlyDigits = rawNumber.replaceAll(RegExp(r'\D'), '');
    final marcaDetectada = _detectMarca(onlyDigits);
    final nuevaTarjeta = Tarjeta(
      id: null,
      idCliente: widget.idCliente,
      marca: marcaDetectada,
      nombreTitular: _nombreController.text.trim(),
      ultimosCuatroDigitos: onlyDigits.substring(onlyDigits.length - 4),
      fechaVencimiento: _vencimientoController.text.trim(),
    );

    debugPrint(
      '[CARD DEBUG] prepared card idCliente=${nuevaTarjeta.idCliente}, '
      'marca=${nuevaTarjeta.marca}, last4=${nuevaTarjeta.ultimosCuatroDigitos}, '
      'vencimiento=${nuevaTarjeta.fechaVencimiento}',
    );

    try {
      final creada = await _tarjetaService.create(
        nuevaTarjeta,
        idCliente: widget.idCliente,
      );
      if (mounted) Navigator.of(context).pop(creada);
    } catch (e) {
      // TarjetaService ya muestra su propio popup de error.
      // Solo detenemos el loading para que el usuario pueda reintentar.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar nueva tarjeta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                maxLength: 19,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 13) {
                    return 'Mínimo 13 dígitos';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(digits) ||
                      RegExp(r'^0+$').hasMatch(digits)) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _numeroController,
                    builder: (context, value, _) {
                      final marca = _detectMarca(value.text);
                      return Text(
                        'Marca detectada: ${marca.isEmpty ? '- -' : marca}',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vencimientoController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Vencimiento (MM/AA)',
                  hintText: '09/28',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final text = v.trim();
                  final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
                  if (!regex.hasMatch(text)) return 'Formato MM/AA';
                  final mm = int.parse(text.substring(0, 2));
                  final yy = int.parse(text.substring(3, 5));
                  if (mm < 1 || mm > 12) return 'Mes inválido';
                  if (yy < 26) return 'Año debe ser 26 o mayor';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: green),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String mm = '';
    String yy = '';

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (digits.length >= 1) {
      mm = digits.substring(0, 1);
    }
    if (digits.length >= 2) {
      mm = digits.substring(0, 2);
      final m = int.tryParse(mm) ?? 0;
      // Reject invalid month as you type
      if (m == 0 || m > 12) {
        return oldValue; // keep previous valid value
      }
    }
    if (digits.length > 2) {
      yy = digits.substring(2, digits.length.clamp(2, 4));
    }

    final composed = yy.isEmpty ? mm : '$mm/$yy';
    final offset = composed.length;
    return TextEditingValue(
      text: composed,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
