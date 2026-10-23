import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Tarjeta.dart' show Tarjeta;
import 'package:flutter_application_1/page/pagos/componentes/NfcPaymentPanel.dart';
import 'package:flutter_application_1/page/pagos/componentes/RegisteredCards.dart';
import 'package:flutter_application_1/widget/app_top_bar.dart';
import 'package:flutter_application_1/service/NfcPaymentController.dart';
import 'package:flutter_application_1/service/PasajeEmergenciaState.dart';
import 'package:flutter_application_1/widget/nfc/emergency_debt_banner.dart';
import 'package:flutter_application_1/widget/nfc/nfc_listen_scope.dart';
import 'package:flutter_application_1/widget/nfcstatusbanner/NfcStatusBanner.dart';

class Pagos extends StatefulWidget {
  final String idCliente;

  const Pagos({super.key, required this.idCliente});

  @override
  State<Pagos> createState() => _PagosState();
}

class _PagosState extends State<Pagos> {
  late final NfcPaymentController _nfc;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _nfc = NfcPaymentController(
      idCliente: widget.idCliente,
      onPagoCompletado: () {
        if (mounted)
          setState(() => _refreshTick++); // recarga saldos del carrusel
      },
    );
    PasajeEmergenciaState.instance.cargar(widget.idCliente);
  }

  @override
  void dispose() {
    _nfc.dispose();
    super.dispose();
  }

  void _onSelectedCardChanged(Tarjeta? card) => _nfc.tarjeta = card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NfcListenScope(
      controller: _nfc,
      child: Column(
        children: [
          AppTopBar(
            title: 'Pagos',
            subtitle: 'Pago sin contacto con tu tarjeta',
          ),
          const EmergencyDebtBanner(),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  const NfcStatusBanner(),

                  NfcPaymentPanel(controller: _nfc),
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
      ),
    );
  }
}
