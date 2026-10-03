import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/pagos/componentes/NfcPayment.dart'
    show NfcPayment;
import 'package:flutter_application_1/page/pagos/componentes/RegisteredCards.dart';
import 'package:flutter_application_1/model/Tarjeta.dart' show Tarjeta;
import 'package:flutter_application_1/page/pagos/componentes/TopBar.dart';

class Pagos extends StatefulWidget {
  final String idCliente;

  const Pagos({super.key, required this.idCliente});

  @override
  State<Pagos> createState() => _PagosState();
}

class _PagosState extends State<Pagos> {
  Tarjeta? _selectedCard;

  // RegisteredCards avisa la selección después de cada carga/recarga.
  // Llega null cuando el cliente ya no tiene tarjetas.
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
              padding: const EdgeInsets.all(20),
              children: [
                // Acción NFC que usa la tarjeta seleccionada del carrusel
                NfcPayment(
                  idCliente: widget.idCliente,
                  selectedTarjeta: _selectedCard,
                ),
                // Carrusel horizontal de tarjetas
                RegisteredCards(
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
