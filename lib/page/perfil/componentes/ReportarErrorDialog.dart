import 'package:flutter/material.dart';

/// Abre el diálogo para reportar un error.
Future<void> showReportarErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const ReportarErrorDialog(),
  );
}

class ReportarErrorDialog extends StatefulWidget {
  const ReportarErrorDialog({super.key});

  @override
  State<ReportarErrorDialog> createState() => _ReportarErrorDialogState();
}

class _ReportarErrorDialogState extends State<ReportarErrorDialog> {
  final TextEditingController _controller = TextEditingController();

  bool get _puedeEnviar => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    // TODO: integrar el servicio de reportes.
    // En este momento el envío todavía no se guarda en el servidor.

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Formulario listo. Falta conectar el servicio de reportes.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
          icon: const Icon(Icons.send_rounded, size: 17),
          label: const Text('Enviar'),
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
    );
  }
}
