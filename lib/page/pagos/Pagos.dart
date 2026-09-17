import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/pagos/componentes/NfcPayment.dart'
    show NfcPayment;
import 'package:flutter_application_1/page/pagos/componentes/RegisteredCards.dart';
import 'package:flutter_application_1/page/pagos/componentes/TopBar.dart';

class Pagos extends StatefulWidget {
  final String idCliente;

  const Pagos({super.key, required this.idCliente});

  @override
  State<Pagos> createState() => _PagosState();
}

class _PagosState extends State<Pagos> {
  int _refreshTick = 0;

  void _onCardsChanged() {
    // Forzar que NfcPayment se reconstruya desde cero (initState) y recargue
    setState(() => _refreshTick++);
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
              padding: const EdgeInsets.all(20),
              children: [
                // Al cambiar la key, se recrea el State y se vuelven a cargar las tarjetas
                NfcPayment(
                  key: ValueKey(_refreshTick),
                  idCliente: widget.idCliente,
                ),
                RegisteredCards(
                  idCliente: widget.idCliente,
                  onCardsChanged: _onCardsChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
