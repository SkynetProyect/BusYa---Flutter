import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/ResumenGasto.dart';
import 'package:flutter_application_1/service/GastoService.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

final NumberFormat _pesos = NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
);

DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Hoja inferior con el resumen de gasto de un periodo.
class ResumenGastoSheet extends StatefulWidget {
  const ResumenGastoSheet({
    super.key,
    required this.titulo,
    required this.desde,
    required this.hasta,
    this.onVerHistorial,
    this.onLoaded,
    this.service,
  });

  final String titulo;
  final DateTime desde;
  final DateTime hasta;
  final VoidCallback? onVerHistorial;

  /// Se llama cuando los datos cargaron (útil para decirlos en voz alta).
  final ValueChanged<ResumenGasto>? onLoaded;
  final GastoService? service;

  static Future<void> show(
    BuildContext context, {
    required String titulo,
    required DateTime desde,
    required DateTime hasta,
    VoidCallback? onVerHistorial,
    ValueChanged<ResumenGasto>? onLoaded,
  }) async {
    await initializeDateFormatting('es_CO');
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => ResumenGastoSheet(
        titulo: titulo,
        desde: desde,
        hasta: hasta,
        onVerHistorial: onVerHistorial,
        onLoaded: onLoaded,
      ),
    );
  }

  @override
  State<ResumenGastoSheet> createState() => _ResumenGastoSheetState();
}

class _ResumenGastoSheetState extends State<ResumenGastoSheet> {
  late final GastoService _service = widget.service ?? GastoService();
  late Future<ResumenGasto> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<ResumenGasto> _cargar() async {
    final resumen = await _service.resumen(
      desde: widget.desde,
      hasta: widget.hasta,
    );
    if (mounted) widget.onLoaded?.call(resumen);
    return resumen;
  }

  void _reintentar() => setState(() => _future = _cargar());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fin = DateTime(
      widget.hasta.year,
      widget.hasta.month,
      widget.hasta.day - 1,
    );
    final formato = DateFormat('d MMM', 'es_CO');
    final mismoDia = _soloFecha(fin) == _soloFecha(widget.desde);
    final subtitulo = mismoDia
        ? formato.format(widget.desde)
        : '${formato.format(widget.desde)} – ${formato.format(fin)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titulo, style: theme.textTheme.titleLarge),
            Text(
              subtitulo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<ResumenGasto>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _Cargando();
                }
                if (snapshot.hasError) {
                  return _Error(onRetry: _reintentar);
                }
                final resumen = snapshot.requireData;
                if (resumen.viajes == 0) return const _Vacio();
                return _Detalle(
                  resumen: resumen,
                  desde: widget.desde,
                  hasta: widget.hasta,
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onVerHistorial?.call();
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver historial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 200,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No hiciste viajes en este periodo.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar tu gasto. Revisa tu conexión.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({
    required this.resumen,
    required this.desde,
    required this.hasta,
  });

  final ResumenGasto resumen;
  final DateTime desde;
  final DateTime hasta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _pesos.format(resumen.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Total gastado $total',
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                total,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Dato(
                icono: Icons.directions_bus_outlined,
                etiqueta: 'Viajes',
                valor: '${resumen.viajes}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Dato(
                icono: Icons.payments_outlined,
                etiqueta: 'Promedio por viaje',
                valor: _pesos.format(resumen.promedio),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Gasto por día', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        _Barras(porDia: resumen.porDia, desde: desde, hasta: hasta),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            etiqueta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(valor, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Barras extends StatelessWidget {
  const _Barras({
    required this.porDia,
    required this.desde,
    required this.hasta,
  });

  final List<GastoDia> porDia;
  final DateTime desde;
  final DateTime hasta;

  static const double _altoMaximo = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final totales = <DateTime, num>{
      for (final d in porDia) _soloFecha(d.dia): d.total,
    };

    final dias = <DateTime>[];
    for (
      var d = _soloFecha(desde);
      d.isBefore(hasta);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      dias.add(d);
    }
    if (dias.isEmpty || dias.length > 62) return const SizedBox.shrink();

    final maximo = totales.values.fold<num>(0, (a, b) => b > a ? b : a);
    final conEtiquetas = dias.length <= 7;
    final formatoDia = DateFormat('d MMM', 'es_CO');
    final formatoSemana = DateFormat('E', 'es_CO');

    return SizedBox(
      height: _altoMaximo + (conEtiquetas ? 26 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final dia in dias)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dias.length > 14 ? 1 : 4,
                ),
                child: Tooltip(
                  message:
                      '${formatoDia.format(dia)}: ${_pesos.format(totales[dia] ?? 0)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _alto(totales[dia] ?? 0, maximo),
                        decoration: BoxDecoration(
                          color: _color(colors, totales[dia] ?? 0, maximo),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (conEtiquetas) ...[
                        const SizedBox(height: 6),
                        Text(
                          formatoSemana
                              .format(dia)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _alto(num valor, num maximo) {
    if (valor <= 0 || maximo <= 0) return 4;
    return (valor / maximo * _altoMaximo).clamp(6.0, _altoMaximo);
  }

  Color _color(ColorScheme colors, num valor, num maximo) {
    if (valor <= 0) return colors.outlineVariant;
    if (valor == maximo) return colors.primary;
    return colors.primary.withValues(alpha: 0.55);
  }
}
