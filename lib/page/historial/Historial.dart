import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/app_top_bar.dart';
import '../../../model/EntradaHistorial.dart';
import '../../../model/TransaccionNfc.dart';
import '../../../service/rest/transaccion_nfc/TransaccionNfcService.dart';
import '../../widget/transactiontile/EntradaHistorialTile.dart';

class Historial extends StatefulWidget {
  final String idCliente;

  const Historial({super.key, required this.idCliente});

  @override
  State<Historial> createState() => _Historial();
}

class _Historial extends State<Historial> {
  final _transaccionService = TransaccionNfcService();
  late Future<List<TransaccionNfc>> _futureTransacciones;

  @override
  void initState() {
    super.initState();
    _futureTransacciones = _cargar();
  }

  Future<List<TransaccionNfc>> _cargar() =>
      _transaccionService.getHistorialPorUsuario(widget.idCliente);

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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppTopBar(
            title: 'Historial',
            subtitle: 'Consulta tus transacciones anteriores',
          ),
          Expanded(
            child: RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: _refrescar,
              child: FutureBuilder<List<TransaccionNfc>>(
                future: _futureTransacciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return _estadoVacio('No se pudo cargar el historial');
                  }

                  final lista = snapshot.data ?? const <TransaccionNfc>[];
                  if (lista.isEmpty) {
                    return _estadoVacio('Aún no registras pasajes pagados');
                  }

                  // Una fila de emergencia pagada pasa a ser dos entradas.
                  final entradas = expandirHistorial(lista);

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: entradas.length,
                          itemBuilder: (_, i) =>
                              EntradaHistorialTile(entrada: entradas[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Scrollable para que el pull-to-refresh también funcione sin datos
  Widget _estadoVacio(String texto) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(
              texto,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
