import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/puntos/water_fill_circle.dart';
import 'package:flutter_application_1/widget/app_top_bar.dart';
import '../../service/puntos_service.dart';

class PuntosEcoScreen extends StatefulWidget {
  const PuntosEcoScreen({super.key});

  @override
  State<PuntosEcoScreen> createState() => _PuntosEcoScreenState();
}

class _PuntosEcoScreenState extends State<PuntosEcoScreen> {
  final PuntosService _service = PuntosService();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      await _service.obtenerEstado();
    } catch (_) {
      // Se queda con el último estado conocido.
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(
            title: 'Puntos Eco',
            subtitle: 'Cada viaje llena tu medidor',
            showBack: true,
            showEcoPoints: false, // aquí ya está el medidor grande
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ValueListenableBuilder<PuntosEstado>(
                      valueListenable: _service.estado,
                      builder: (context, e, _) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        children: [
                          _Medidor(estado: e),
                          if (e.pasajesGratis > 0) ...[
                            const SizedBox(height: 14),
                            _BannerPasaje(cantidad: e.pasajesGratis),
                          ],
                          const SizedBox(height: 28),
                          Text(
                            '¿Cómo funciona?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _InfoTile(
                            icon: Icons.nfc,
                            title: 'Paga con NFC y suma 1 punto',
                            subtitle:
                                'Cada vez que validas tu pasaje en un bus del sistema, el medidor sube.',
                          ),
                          const SizedBox(height: 10),
                          const _InfoTile(
                            icon: Icons.water_drop_outlined,
                            title: 'Llena el medidor: 30 puntos',
                            subtitle:
                                'Al completarlo ganas un pasaje gratis y el medidor vuelve a cero.',
                          ),
                          const SizedBox(height: 10),
                          const _InfoTile(
                            icon: Icons.redeem_outlined,
                            title: 'Se usa solo en tu próximo viaje',
                            subtitle:
                                'No tienes que hacer nada: al pagar, te avisamos que fue con tu pasaje Eco.',
                          ),
                          const SizedBox(height: 10),
                          const _InfoTile(
                            icon: Icons.park_outlined,
                            title: 'Impacto ambiental',
                            subtitle:
                                'Incentivamos la movilidad masiva para reducir emisiones en el Valle de Aburrá.',
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

Color _acento(BuildContext context) => Theme.of(context).colorScheme.primary;

class _Medidor extends StatelessWidget {
  final PuntosEstado estado;
  const _Medidor({required this.estado});

  String get _mensaje {
    if (estado.puntos == 0)
      return '¡Haz tu primer viaje para empezar a llenar!';
    if (estado.faltan == 1) return '¡Te falta 1 viaje para tu pasaje gratis!';
    return 'Te faltan ${estado.faltan} viajes para tu pasaje gratis';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
        child: Column(
          children: [
            WaterFillCircle(
              size: 220,
              progress: estado.progreso,
              valueText: '${estado.puntos}',
              captionText: 'de $kMetaPuntosEco puntos',
              waterColor: theme.colorScheme.primary,
              semanticLabel:
                  '${estado.puntos} de $kMetaPuntosEco puntos Eco acumulados',
            ),
            const SizedBox(height: 20),
            Text(
              _mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Hito(valor: 10, alcanzado: estado.puntos >= 10),
                _Hito(valor: 20, alcanzado: estado.puntos >= 20),
                _Hito(valor: kMetaPuntosEco, alcanzado: false, esMeta: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hito extends StatelessWidget {
  final int valor;
  final bool alcanzado;
  final bool esMeta;
  const _Hito({
    required this.valor,
    required this.alcanzado,
    this.esMeta = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acento = _acento(context);
    final sobreAcento = theme.colorScheme.onPrimary;

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: alcanzado ? acento : Colors.transparent,
            border: Border.all(
              color: alcanzado || esMeta
                  ? acento
                  : theme.dividerColor.withValues(alpha: 0.65),
              width: 2,
            ),
          ),
          child: esMeta
              ? Icon(Icons.redeem_outlined, color: acento, size: 22)
              : alcanzado
              ? Icon(Icons.check, color: sobreAcento, size: 22)
              : Text('$valor', style: theme.textTheme.labelLarge),
        ),
        const SizedBox(height: 6),
        Text(
          esMeta ? 'Pasaje gratis' : '$valor pts',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BannerPasaje extends StatelessWidget {
  final int cantidad;
  const _BannerPasaje({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acento = _acento(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: acento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: acento.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.redeem_outlined, color: acento, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cantidad == 1
                  ? 'Tienes 1 pasaje gratis. Se usará automáticamente en tu próximo pago. Si tienes un pasaje de emergencia pendiente, págalo primero.'
                  : 'Tienes $cantidad pasajes gratis. Se usarán automáticamente en tus próximos pagos. Si tienes un pasaje de emergencia pendiente, págalo primero.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acento = _acento(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: acento.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: acento, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
