import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/page/pagos/componentes/NfcPaymentPanel.dart';
import 'package:flutter_application_1/service/NfcPaymentController.dart';
import 'package:flutter_application_1/service/PasajeEmergenciaState.dart';
import 'package:flutter_application_1/widget/nfc/emergency_debt_banner.dart';
import 'package:flutter_application_1/widget/nfc/nfc_listen_scope.dart';
import 'package:flutter_application_1/widget/nfcstatusbanner/NfcStatusBanner.dart';
import '../../../model/EntradaHistorial.dart';
import '../../../model/Tarjeta.dart';
import '../../../model/TransaccionNfc.dart';
import '../../../service/rest/transaccion_nfc/TransaccionNfcService.dart';
import '../../widget/registeredcardvisual/RegisteredCardVisual.dart';
import '../../widget/transactiontile/EntradaHistorialTile.dart';

class CardDetailHistoryPage extends StatefulWidget {
  final String idCliente;
  final Tarjeta tarjeta;

  const CardDetailHistoryPage({
    super.key,
    required this.idCliente,
    required this.tarjeta,
  });

  @override
  State<CardDetailHistoryPage> createState() => _CardDetailHistoryPageState();
}

class _CardDetailHistoryPageState extends State<CardDetailHistoryPage> {
  final _transaccionService = TransaccionNfcService();
  late Future<List<TransaccionNfc>> _futureTransacciones;
  late final NfcPaymentController _nfc;

  @override
  void initState() {
    super.initState();
    _futureTransacciones = _cargar();
    _nfc = NfcPaymentController(
      idCliente: widget.idCliente,
      onPagoCompletado: () {
        if (mounted) _refrescar(); // el pago nuevo aparece en la lista
      },
    )..tarjeta = widget.tarjeta;
    PasajeEmergenciaState.instance.cargar(
      widget.idCliente,
    ); // ya cacheado si vienes de Pagos
  }

  @override
  void dispose() {
    _nfc.dispose();
    super.dispose();
  }

  Future<List<TransaccionNfc>> _cargar() {
    final id = widget.tarjeta.id;
    if (id == null) return Future.value(const <TransaccionNfc>[]);
    return _transaccionService.getHistorialPorTarjeta(widget.idCliente, id);
  }

  Future<void> _refrescar() async {
    setState(() => _futureTransacciones = _cargar());
    try {
      await _futureTransacciones;
    } catch (_) {
      // El error se muestra en el FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return NfcListenScope(
      controller: _nfc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
          title: Text(
            widget.tarjeta.nombreTitular,
            style: const TextStyle(color: AppColors.text),
          ),
        ),
        body: Column(
          children: [
            const EmergencyDebtBanner(), // debajo del appbar, sin cerrar
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: _refrescar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const NfcStatusBanner(),
                    NfcPaymentPanel(controller: _nfc),
                    RegisteredCardVisual(
                      tarjeta: widget.tarjeta,
                      selected: true,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Transacciones',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<TransaccionNfc>>(
                      future: _futureTransacciones,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const _Mensaje(
                            'No se pudo cargar el historial',
                          );
                        }
                        final lista = snapshot.data ?? const <TransaccionNfc>[];
                        if (lista.isEmpty) {
                          return const _Mensaje(
                            'No hay transacciones registradas con esta tarjeta',
                          );
                        }

                        // Una fila de emergencia pagada pasa a ser dos entradas.
                        final entradas = expandirHistorial(lista);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: entradas.length,
                            itemBuilder: (_, i) => EntradaHistorialTile(
                              entrada: entradas[i],
                              mostrarTarjeta: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String texto;
  const _Mensaje(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text),
        ),
      ),
    );
  }
}
