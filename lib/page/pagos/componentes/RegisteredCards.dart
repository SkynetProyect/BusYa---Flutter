import 'package:flutter/material.dart';

import 'package:flutter_application_1/model/Tarjeta.dart';
import 'package:flutter_application_1/page/pagos/componentes/AddCardDialog.dart';
import 'package:flutter_application_1/service/rest/tarjeta/TarjetaService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisteredCards extends StatefulWidget {
  final String idCliente;
  final VoidCallback? onCardsChanged;
  final void Function(Tarjeta selected)? onSelectedChanged;

  const RegisteredCards({
    super.key,
    required this.idCliente,
    this.onCardsChanged,
    this.onSelectedChanged,
  });

  @override
  State<RegisteredCards> createState() => _RegisteredCardsState();
}

class _RegisteredCardsState extends State<RegisteredCards> {
  final TarjetaService _tarjetaService = TarjetaService();

  late Future<List<Tarjeta>> _futureTarjetas;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;
  List<Tarjeta> _tarjetas = const [];

  static const green = Color(0xFF1E8A5F);

  @override
  void initState() {
    super.initState();
    if (widget.idCliente.isEmpty) {
      _futureTarjetas = Future.value(const <Tarjeta>[]);
    } else {
      _loadTarjetas();
    }

    _pageController.addListener(() {
      // Listener for animation; selection is handled in onPageChanged
    });
  }

  void _loadTarjetas() {
    _futureTarjetas = _tarjetaService.getByClienteId(widget.idCliente).then((
      list,
    ) async {
      _tarjetas = list;
      // Restaurar selección persistida
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('selected_card_${widget.idCliente}');
      int initial = 0;
      if (savedId != null) {
        final idx = _tarjetas.indexWhere((t) => t.id?.toString() == savedId);
        if (idx >= 0) initial = idx;
      }
      _currentIndex = initial.clamp(
        0,
        _tarjetas.isEmpty ? 0 : _tarjetas.length - 1,
      );
      // Mover el pageController cuando las tarjetas estén listas en build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
        if (_tarjetas.isNotEmpty && widget.onSelectedChanged != null) {
          widget.onSelectedChanged!(_tarjetas[_currentIndex]);
        }
      });
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
      'last4=${tarjeta.ultimosCuatroDigitos}, idClienteWidget=${widget.idCliente}',
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
        const SizedBox(height: 8),

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

            // Guardar en estado y construir carrusel
            _tarjetas = tarjetas;
            return Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _tarjetas.length,
                    onPageChanged: (i) async {
                      _currentIndex = i;
                      final selected = _tarjetas[i];
                      if (widget.onSelectedChanged != null) {
                        widget.onSelectedChanged!(selected);
                      }
                      // Persistir selección
                      final prefs = await SharedPreferences.getInstance();
                      if (selected.id != null) {
                        await prefs.setString(
                          'selected_card_${widget.idCliente}',
                          selected.id.toString(),
                        );
                      }
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          double opacity = 1.0;
                          if (_pageController.position.haveDimensions) {
                            final page =
                                _pageController.page ??
                                _currentIndex.toDouble();
                            final diff = (page - index).abs().clamp(0.0, 1.0);
                            scale = 1.0 - (diff * 0.06);
                            opacity = 1.0 - (diff * 0.25);
                          }
                          return Center(
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: _CardTile(
                                    tarjeta: _tarjetas[index],
                                    onDelete: () =>
                                        _handleDelete(_tarjetas[index]),
                                    selected: index == _currentIndex,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 4),

        // Botón "Registrar nueva tarjeta"
        DottedBorderButton(onTap: _handleAddCard),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _CardTile extends StatelessWidget {
  final Tarjeta tarjeta;
  final VoidCallback onDelete;
  final bool selected;

  const _CardTile({
    required this.tarjeta,
    required this.onDelete,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _brandGradientFor(tarjeta.marca);
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(selected ? 0.35 : 0.15),
            blurRadius: selected ? 14 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: selected
            ? Border.all(color: Colors.white.withOpacity(0.8), width: 1.2)
            : null,
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

List<Color> _brandGradientFor(String marca) {
  final m = marca.trim().toUpperCase();
  if (m.contains('VISA')) {
    // Blue marine
    return const [Color(0xFF0A3D91), Color(0xFF1E5AB6)];
  }
  if (m.contains('AMEX') || m.contains('AMERICAN')) {
    // Light green for Amex
    return const [Color(0xFF66BB6A), Color(0xFF9CCC65)];
  }
  if (m.contains('MASTER')) {
    // Dark opaque yellow for Mastercard
    return const [Color(0xFFF9A825), Color(0xFFFBC02D)];
  }
  // Default green theme
  return const [Color(0xFF1B5E20), Color(0xFF43A047)];
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
