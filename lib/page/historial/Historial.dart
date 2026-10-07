import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/page/historial/componentes/TopBar.dart';
import '../../../model/TransaccionNfc.dart';
import '../../../service/rest/transaccion_nfc/TransaccionNfcService.dart';
import '../../widget/transactiontile/TransactionTile.dart';

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.green,
              onRefresh: _refrescar,
              child: FutureBuilder<List<TransaccionNfc>>(
                future: _futureTransacciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.green,
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

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              TransactionTile(transaccion: lista[i]),
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
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(texto, style: const TextStyle(color: AppColors.text)),
          ),
        ),
      ],
    );
  }
}
