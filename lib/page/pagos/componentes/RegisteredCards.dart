import 'package:flutter/material.dart';

import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/page/pagos/componentes/AddCardDialog.dart';
import 'package:flutter_application_1/service/rest/tarjeta/TarjetaService.dart';

class RegisteredCards extends StatefulWidget {
  final int idCliente;

  const RegisteredCards({super.key, required this.idCliente});

  @override
  State<RegisteredCards> createState() => _RegisteredCardsState();
}

class _RegisteredCardsState extends State<RegisteredCards> {
  final TarjetaService _tarjetaService = TarjetaService();

  late Future<List<Tarjeta>> _futureTarjetas;

  static const green = Color(0xFF1E8A5F);

  @override
  void initState() {
    super.initState();
    _loadTarjetas();
  }

  void _loadTarjetas() {
    _futureTarjetas = _tarjetaService.getByClienteId(widget.idCliente);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTarjetas();
    });
  }

  Future<void> _handleDelete(Tarjeta tarjeta) async {
    if (tarjeta.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text(
          '¿Seguro que deseas eliminar la tarjeta terminada en ${tarjeta.numero.toString().padLeft(4, '0').substring(tarjeta.numero.toString().length > 4 ? tarjeta.numero.toString().length - 4 : 0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tarjetaService.delete(tarjeta.id!);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarjeta eliminada')));
      }
    } catch (e) {
      // TarjetaService ya mostró el popup de error; no hace falta duplicar.
    }
  }

  Future<void> _handleAddCard() async {
    final creada = await showAddCardDialog(
      context,
      idCliente: widget.idCliente,
    );

    if (creada != null) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarjeta registrada')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tarjetas registradas",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        FutureBuilder<List<Tarjeta>>(
          future: _futureTarjetas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: green)),
              );
            }

            if (snapshot.hasError) {
              // El popup con el detalle ya lo mostró TarjetaService.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'No se pudieron cargar tus tarjetas.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final tarjetas = snapshot.data ?? [];

            if (tarjetas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aún no tienes tarjetas registradas',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              );
            }

            return Column(
              children: tarjetas
                  .map(
                    (tarjeta) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CardTile(
                        tarjeta: tarjeta,
                        onDelete: () => _handleDelete(tarjeta),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 4),

        // Botón "Registrar nueva tarjeta"
        DottedBorderButton(onTap: _handleAddCard),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final Tarjeta tarjeta;
  final VoidCallback onDelete;

  const _CardTile({required this.tarjeta, required this.onDelete});

  static const green = Color(0xFF1E8A5F);

  String get _numeroEnmascarado {
    final numeroStr = tarjeta.numero.toString();
    final ultimos4 = numeroStr.length >= 4
        ? numeroStr.substring(numeroStr.length - 4)
        : numeroStr.padLeft(4, '0');
    return '•••• $ultimos4';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card, color: green, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${tarjeta.marca} $_numeroEnmascarado",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${tarjeta.nombre} · vence ${tarjeta.vencimiento}",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: green, size: 20),
          ),
        ],
      ),
    );
  }
}

// Botón con borde punteado
class DottedBorderButton extends StatelessWidget {
  final VoidCallback onTap;
  const DottedBorderButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1E8A5F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: green, radius: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: green, size: 18),
              SizedBox(width: 6),
              Text(
                "Registrar nueva tarjeta",
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _dashPath(path, dashLength: 5, gapLength: 4);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
