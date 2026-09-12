import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart';
import 'package:flutter_application_1/model/Ruta.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart';
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart';
import 'package:flutter_application_1/service/rest/tarjeta/TarjetaService.dart';

class NfcPayment extends StatefulWidget {
  final String idCliente;
  final void Function(Empresa empresa, Ruta ruta, Tarjeta tarjeta)? onPagar;

  const NfcPayment({super.key, required this.idCliente, this.onPagar});

  @override
  State<NfcPayment> createState() => _NfcPaymentState();
}

class _NfcPaymentState extends State<NfcPayment> {
  static const green = Color(0xFF1E8A5F);

  final _empresaService = EmpresaService();
  final _rutaService = RutaService();
  final _tarjetaService = TarjetaService();

  late Future<List<Empresa>> _futureEmpresas;
  Future<List<Ruta>>? _futureRutas;
  Future<List<Tarjeta>>? _futureTarjetas;

  Empresa? _empresaSeleccionada;
  Ruta? _rutaSeleccionada;
  Tarjeta? _tarjetaSeleccionada;

  @override
  void initState() {
    super.initState();
    _futureEmpresas = _empresaService.getAll();
    _futureTarjetas = _tarjetaService.getByClienteId(widget.idCliente);
  }

  void _onEmpresaChanged(Empresa? empresa) {
    setState(() {
      _empresaSeleccionada = empresa;
      _rutaSeleccionada = null;
      _futureRutas = empresa != null
          ? _rutaService.getByEmpresaId(empresa.id!)
          : null;
    });
  }

  void _onRutaChanged(Ruta? ruta) {
    setState(() => _rutaSeleccionada = ruta);
  }

  void _onTarjetaChanged(Tarjeta? tarjeta) {
    setState(() => _tarjetaSeleccionada = tarjeta);
  }

  bool get _listoParaPagar =>
      _empresaSeleccionada != null &&
      _rutaSeleccionada != null &&
      _tarjetaSeleccionada != null;

  void _handlePagar() {
    if (!_listoParaPagar) return;
    widget.onPagar?.call(
      _empresaSeleccionada!,
      _rutaSeleccionada!,
      _tarjetaSeleccionada!,
    );
  }

  String _numeroEnmascarado(Tarjeta tarjeta) {
    return '•••• ${tarjeta.ultimosCuatroDigitos}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Selector de Empresa ---
        FutureBuilder<List<Empresa>>(
          future: _futureEmpresas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loadingCard('Cargando empresas...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _errorCard('No se pudieron cargar las empresas');
            }
            final empresas = snapshot.data!;
            return _DropdownCard<Empresa>(
              hint: 'Selecciona una empresa',
              value: _empresaSeleccionada,
              items: empresas
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.nombre)))
                  .toList(),
              onChanged: _onEmpresaChanged,
            );
          },
        ),

        const SizedBox(height: 12),

        // --- Selector de Ruta (depende de Empresa) ---
        if (_empresaSeleccionada != null)
          FutureBuilder<List<Ruta>>(
            future: _futureRutas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingCard('Cargando rutas...');
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _errorCard('No se pudieron cargar las rutas');
              }
              final rutas = snapshot.data!;
              if (rutas.isEmpty) {
                return _errorCard('Esta empresa no tiene rutas disponibles');
              }
              return _DropdownCard<Ruta>(
                hint: 'Selecciona una ruta',
                value: _rutaSeleccionada,
                items: rutas
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.nombre)),
                    )
                    .toList(),
                onChanged: _onRutaChanged,
              );
            },
          ),

        if (_empresaSeleccionada != null) const SizedBox(height: 12),

        // --- Selector de Tarjeta ---
        if (_rutaSeleccionada != null)
          FutureBuilder<List<Tarjeta>>(
            future: _futureTarjetas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _loadingCard('Cargando tarjetas...');
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _errorCard('No se pudieron cargar tus tarjetas');
              }
              final tarjetas = snapshot.data!;
              if (tarjetas.isEmpty) {
                return _errorCard('No tienes tarjetas registradas');
              }
              return _DropdownCard<Tarjeta>(
                hint: 'Selecciona una tarjeta',
                value: _tarjetaSeleccionada,
                items: tarjetas
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.marca} ${_numeroEnmascarado(t)}'),
                      ),
                    )
                    .toList(),
                onChanged: _onTarjetaChanged,
              );
            },
          ),

        if (_rutaSeleccionada != null) const SizedBox(height: 12),

        // --- Tarjeta de pago NFC ---
        if (_listoParaPagar) _buildPaymentCard(),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi,
            color: green,
            size: 40,
          ), // placeholder NFC icon
          const SizedBox(height: 12),
          // TODO: Ruta no tiene campo `precio` — ajusta esto según
          // cómo calcules la tarifa (fijo, por distancia, etc.)
          const Text(
            '\$ 3.200',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_tarjetaSeleccionada!.marca} ${_numeroEnmascarado(_tarjetaSeleccionada!)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handlePagar,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Pagar con NFC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: green),
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: Colors.red.shade700),
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownCard({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
