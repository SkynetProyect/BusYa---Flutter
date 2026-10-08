import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Tarjeta.dart' show Tarjeta;
import 'package:flutter_application_1/page/pagos/componentes/EmergencyPayment.dart';
import 'package:flutter_application_1/page/pagos/componentes/NfcPayment.dart'
    show NfcPayment;
import 'package:flutter_application_1/page/pagos/componentes/RegisteredCards.dart';
import 'package:flutter_application_1/page/pagos/componentes/TopBar.dart';
import 'package:flutter_application_1/service/rest/transaccion_nfc/TransaccionNfcService.dart';

class Pagos extends StatefulWidget {
  final String idCliente;

  const Pagos({super.key, required this.idCliente});

  @override
  State<Pagos> createState() => _PagosState();
}

class _PagosState extends State<Pagos> {
  final TransaccionNfcService _transaccionService = TransaccionNfcService();

  Tarjeta? _selectedCard;
  Map<String, dynamic>? _pendiente;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _cargarPendiente();
  }

  Future<void> _cargarPendiente() async {
    final resp = await _transaccionService.getEmergenciaPendiente(
      widget.idCliente,
    );
    if (!mounted) return;
    setState(() => _pendiente = resp);
  }

  void _onEmergenciaPagada() {
    setState(() => _refreshTick++); // el carrusel recarga los saldos/tarjetas
    _cargarPendiente();
  }

  void _onSelectedCardChanged(Tarjeta? card) {
    if (!mounted) return;
    setState(() => _selectedCard = card);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Container(
            color: const Color(0xFFF6F7FB),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                // 1. Mostrar condicionalmente pago de emergencia o acción NFC
                if (_pendiente != null)
                  EmergencyPayment(
                    idCliente: widget.idCliente,
                    monto: _pendiente!['monto'],
                    selectedTarjeta: _selectedCard,
                    onPagado: _onEmergenciaPagada,
                  )
                else
                  NfcPayment(
                    idCliente: widget.idCliente,
                    selectedTarjeta: _selectedCard,
                    onDeudaPendiente: _cargarPendiente,
                  ),

                // 2. Carrusel horizontal de tarjetas registradas
                RegisteredCards(
                  key: ValueKey(_refreshTick),
                  idCliente: widget.idCliente,
                  onSelectedChanged: _onSelectedCardChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
