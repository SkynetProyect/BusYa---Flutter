import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return NfcListenScope(
      controller: _nfc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? colors.surface,
          elevation: 0,
          iconTheme: IconThemeData(
            color: theme.appBarTheme.iconTheme?.color ?? colors.onSurface,
          ),
          title: Text(
            widget.tarjeta.nombreTitular,
            style: TextStyle(color: colors.onSurface),
          ),
        ),
        body: Column(
          children: [
            const EmergencyDebtBanner(), // debajo del appbar, sin cerrar
            Expanded(
              child: RefreshIndicator(
                color: colors.primary,
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
                    Text(
                      'Transacciones',
                      style: TextStyle(
                        color: colors.onSurface,
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colors.primary,
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
                        final entradas = expandirHistorialTarjeta(
                          lista,
                          widget.tarjeta.id ?? -1,
                        );

                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
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
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}
