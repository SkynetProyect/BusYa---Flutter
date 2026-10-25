import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Reporte.dart' show Reporte;
import 'package:flutter_application_1/service/rest/reporte/ReporteService.dart'
    show ReporteService;

/// Abre el diálogo para reportar un error.
/// [idUsuario] es el usuario que está enviando el reporte.
Future<void> showReportarErrorDialog(
  BuildContext context, {
  required String idUsuario,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ReportarErrorDialog(idUsuario: idUsuario),
  );
}

class ReportarErrorDialog extends StatefulWidget {
  final String idUsuario;

  /// Opcional: permite pasar otro servicio (por ejemplo, en pruebas).
  /// Si no se pasa, se usa el [ReporteService] normal.
  final ReporteService? reporteService;

  const ReportarErrorDialog({
    super.key,
    required this.idUsuario,
    this.reporteService,
  });

  @override
  State<ReportarErrorDialog> createState() => _ReportarErrorDialogState();
}

class _ReportarErrorDialogState extends State<ReportarErrorDialog> {
  final TextEditingController _controller = TextEditingController();
  late final ReporteService _servicio =
      widget.reporteService ?? ReporteService();

  bool _enviando = false;
  String? _error;

  bool get _puedeEnviar => _controller.text.trim().isNotEmpty && !_enviando;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      // El id lo genera la base de datos, por eso va en 0.
      final reporte = Reporte(
        id: 0,
        idUsuario: widget.idUsuario,
        texto: _controller.text.trim(),
      );

      await _servicio.crear(reporte);

      if (!mounted) return;
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Gracias, tu reporte fue enviado.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error =
            'No se pudo enviar el reporte. '
            'Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Mientras se envía, no se puede cerrar el diálogo.
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.65)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: colors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reportar un error',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ayúdanos a mejorar BusYA',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuéntanos qué ocurrió para que podamos revisarlo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_enviando,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Describe el error...',
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                filled: true,
                fillColor: isDark
                    ? colors.surface
                    : colors.primary.withValues(alpha: 0.035),
                alignLabelWithHint: true,
                counterStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _enviando ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: _puedeEnviar ? _enviar : null,
            icon: _enviando
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(_enviando ? 'Enviando...' : 'Enviar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
              side: BorderSide(
                color: _puedeEnviar
                    ? colors.primary.withValues(alpha: 0.55)
                    : theme.dividerColor.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
