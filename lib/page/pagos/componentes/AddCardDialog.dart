import 'package:flutter/material.dart';
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

  final _marcaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _numeroController = TextEditingController();
  final _vencimientoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _marcaController.dispose();
    _nombreController.dispose();
    _numeroController.dispose();
    _vencimientoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    debugPrint(
      '[CARD DEBUG] submit widget.idCliente=${widget.idCliente}, '
      'currentUserId=${supabase.auth.currentUser?.id}, '
      'userRole=${supabase.auth.currentUser?.role}',
    );

    final nuevaTarjeta = Tarjeta(
      id: null,
      idCliente: widget.idCliente,
      marca: _marcaController.text.trim(),
      nombreTitular: _nombreController.text.trim(),
      ultimosCuatroDigitos: _numeroController.text.trim().substring(
        _numeroController.text.trim().length - 4,
      ),
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
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca (ej. Visa, Mastercard)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
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
                maxLength: 16,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (int.tryParse(v.trim()) == null || v.trim().length < 4) {
                    return 'Solo números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vencimientoController,
                decoration: const InputDecoration(
                  labelText: 'Vencimiento (MM/AA)',
                  hintText: '09/28',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
                  if (!regex.hasMatch(v.trim())) return 'Formato MM/AA';
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
