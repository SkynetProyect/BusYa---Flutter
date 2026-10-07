import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import '../../../model/Tarjeta.dart';
import '../../../model/TransaccionNfc.dart';
import '../../../service/rest/transaccion_nfc/TransaccionNfcService.dart';
import '../../widget/nfcstatusbanner/NfcStatusBanner.dart';
import '../../widget/transactiontile/TransactionTile.dart';

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

  @override
  void initState() {
    super.initState();
    _futureTransacciones = _cargar();
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
    return Scaffold(
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
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const NfcStatusBanner(),

            // Tarjeta visual
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.tarjeta.marca,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'Débito',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Text(
                    '•••• ${widget.tarjeta.ultimosCuatroDigitos}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const _Mensaje('No se pudo cargar el historial');
                }
                final lista = snapshot.data ?? const <TransaccionNfc>[];
                if (lista.isEmpty) {
                  return const _Mensaje(
                    'No hay transacciones registradas con esta tarjeta',
                  );
                }

                return Container(
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
                    itemBuilder: (_, i) => TransactionTile(
                      transaccion: lista[i],
                      mostrarTarjeta: false,
                    ),
                  ),
                );
              },
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
