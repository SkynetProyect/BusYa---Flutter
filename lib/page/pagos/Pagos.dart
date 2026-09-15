import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/pagos/componentes/NfcPayment.dart';
import 'package:flutter_application_1/page/pagos/componentes/RegisteredCards.dart';
import 'package:flutter_application_1/page/pagos/componentes/TopBar.dart';

class Pagos extends StatelessWidget {
  final String idCliente;

  const Pagos({super.key, required this.idCliente});

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
                NfcPayment(idCliente: idCliente),
                const SizedBox(height: 24),
                RegisteredCards(idCliente: idCliente),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
