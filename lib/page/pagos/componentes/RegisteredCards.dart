import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/page/pagos/componentes/AddCardDialog.dart';
import 'package:flutter_application_1/service/rest/tarjeta/TarjetaService.dart';

class RegisteredCards extends StatefulWidget {
  final String idCliente;
  final VoidCallback? onCardsChanged;

  const RegisteredCards({
    super.key,
    required this.idCliente,
    this.onCardsChanged,
  });

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
    if (widget.idCliente.isEmpty) {
      _futureTarjetas = Future.value(const <Tarjeta>[]);
    } else {
      _loadTarjetas();
    }
  }

  void _loadTarjetas() {
    debugPrint(
      '[CARD DEBUG] RegisteredCards load idCliente=${widget.idCliente}, '
      'currentUserId=${supabase.auth.currentUser?.id}, '
      'hasSession=${supabase.auth.currentSession != null}',
    );
    _futureTarjetas = _tarjetaService.getByClienteId(widget.idCliente).then((
      list,
    ) {
      debugPrint(
        '[CARD DEBUG] RegisteredCards loaded '
        '${list.length} cards: ids='
        '${list.map((t) => t.id).toList()}',
      );
      return list;
    });
  }

  @override
  void didUpdateWidget(covariant RegisteredCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idCliente == widget.idCliente) return;

    setState(() {
      if (widget.idCliente.isEmpty) {
        _futureTarjetas = Future.value(const <Tarjeta>[]);
      } else {
        _loadTarjetas();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTarjetas();
    });
  }

  Future<void> _handleDelete(Tarjeta tarjeta) async {
    if (tarjeta.id == null) return;

    debugPrint(
      '[CARD DEBUG UI] Intentando eliminar tarjeta id=${tarjeta.id}, '
      'last4=${tarjeta.ultimosCuatroDigitos}, idClienteWidget=${widget.idCliente}, '
      'authUser=${supabase.auth.currentUser?.id}',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text(
          '¿Seguro que deseas eliminar la tarjeta terminada en ${tarjeta.ultimosCuatroDigitos}?',
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
      debugPrint(
        '[CARD DEBUG UI] Confirmado. Llamando a service.delete(${tarjeta.id})',
      );
      await _tarjetaService.delete(tarjeta.id!);
      debugPrint('[CARD DEBUG UI] Eliminación OK. Refrescando listas');
      _refresh();
      // Notifica al contenedor (Pagos) para que refresque también
      widget.onCardsChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarjeta eliminada')));
      }
    } catch (e) {
      debugPrint('[CARD DEBUG UI] Error al eliminar: $e');
      // TarjetaService ya mostró el popup de error; no hace falta duplicar.
    }
  }

  Future<void> _handleAddCard() async {
    if (widget.idCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para registrar una tarjeta'),
        ),
      );
      return;
    }

    final creada = await showAddCardDialog(
      context,
      idCliente: widget.idCliente,
    );

    if (creada != null) {
      _refresh();
      widget.onCardsChanged?.call();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tarjeta.marca.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.contactless, color: Colors.white70, size: 28),
            ],
          ),
          Text(
            '•••• •••• •••• ${tarjeta.ultimosCuatroDigitos}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TITULAR',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      tarjeta.nombreTitular,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXP',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  Text(
                    tarjeta.fechaVencimiento,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: tarjeta.id == null
                      ? Colors.redAccent.withOpacity(0.4)
                      : Colors.redAccent,
                ),
                tooltip: 'Eliminar tarjeta',
                onPressed: tarjeta.id == null ? null : onDelete,
              ),
            ],
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
