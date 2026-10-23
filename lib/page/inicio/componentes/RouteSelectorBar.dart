import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;

/// Barra superior con los selectores de Empresa y Ruta.
/// Widget "tonto": solo pinta el estado recibido y notifica
/// las interacciones por callbacks.
class RouteSelectorBar extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Empresa> empresas;
  final List<Ruta> rutas;
  final Empresa? empresaSeleccionada;
  final Ruta? rutaSeleccionada;
  final ValueChanged<Empresa?> onEmpresaChanged;
  final ValueChanged<Ruta?> onRutaChanged;
  final VoidCallback onRetry;

  const RouteSelectorBar({
    super.key,
    required this.loading,
    required this.error,
    required this.empresas,
    required this.rutas,
    required this.empresaSeleccionada,
    required this.rutaSeleccionada,
    required this.onEmpresaChanged,
    required this.onRutaChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          : error != null
          ? _buildError()
          : _buildDropdowns(context),
    );
  }

  /// Mensaje de error con botón de reintento.
  Widget _buildError() {
    return Row(
      children: [
        const Expanded(child: Text('No se pudieron cargar empresas y rutas')),
        IconButton(
          tooltip: 'Reintentar',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  /// Par de dropdowns Empresa | Ruta.
  Widget _buildDropdowns(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: _buildEmpresaDropdown()),
        const SizedBox(width: 8),
        Container(width: 1, height: 28, color: theme.dividerColor),
        const SizedBox(width: 8),
        Expanded(child: _buildRutaDropdown()),
      ],
    );
  }

  Widget _buildEmpresaDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Empresa>(
        isExpanded: true,
        hint: Text(empresas.isEmpty ? 'Sin empresas disponibles' : 'Empresa'),
        value: empresaSeleccionada,
        items: empresas
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e.nombre, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onEmpresaChanged,
      ),
    );
  }

  Widget _buildRutaDropdown() {
    final hint = empresaSeleccionada == null
        ? 'Selecciona una empresa'
        : (rutas.isEmpty ? 'Sin rutas disponibles' : 'Ruta');

    return DropdownButtonHideUnderline(
      child: DropdownButton<Ruta>(
        isExpanded: true,
        hint: Text(hint),
        value: rutaSeleccionada,
        items: rutas
            .map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(r.nombre, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: rutas.isEmpty ? null : onRutaChanged,
      ),
    );
  }
}
