// lib/page/perfil/componentes/ReportarErrorDialog.dart
import 'package:flutter/material.dart';

/// Abre el popup para reportar un error.
/// Se usa desde cualquier pantalla: `showReportarErrorDialog(context);`
Future<void> showReportarErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const ReportarErrorDialog(),
  );
}

/// Popup con un campo de texto y los botones Cancelar / Enviar.
class ReportarErrorDialog extends StatefulWidget {
  const ReportarErrorDialog({super.key});

  @override
  State<ReportarErrorDialog> createState() => _ReportarErrorDialogState();
}

class _ReportarErrorDialogState extends State<ReportarErrorDialog> {
  final TextEditingController _controller = TextEditingController();

  /// Habilita "Enviar" solo si hay texto escrito.
  bool get _puedeEnviar => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Envía el reporte y cierra el popup.
  void _enviar() {
    // TODO: llamar al servicio de reportes cuando exista,
    // enviando `_controller.text.trim()`.

    // Se captura antes de cerrar para poder mostrar el mensaje después.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Tu reporte fue enviado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar error'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Describe el error...',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}), // Actualiza el estado del botón.
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _puedeEnviar ? _enviar : null,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
