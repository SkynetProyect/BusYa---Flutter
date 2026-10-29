import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/puntos/puntos_eco_screen.dart';
import 'package:flutter_application_1/service/puntos_service.dart';
import 'package:flutter_application_1/widget/puntos/water_fill_circle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mini medidor para el AppTopBar: gotita que se llena + "12/30".
/// Se actualiza solo cuando cambia PuntosService().estado.
/// Al tocarlo abre la pantalla de Puntos Eco.
class PuntosEcoChip extends StatefulWidget {
  const PuntosEcoChip({super.key});

  @override
  State<PuntosEcoChip> createState() => _PuntosEcoChipState();
}

class _PuntosEcoChipState extends State<PuntosEcoChip> {
  final _service = PuntosService();

  @override
  void initState() {
    super.initState();
    _service.obtenerEstado().catchError((_) => const PuntosEstado());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PuntosEstado>(
      valueListenable: _service.estado,
      builder: (context, e, _) {
        // Sin sesión no hay puntos que mostrar.
        if (Supabase.instance.client.auth.currentUser == null) {
          return const SizedBox.shrink();
        }
        return Semantics(
          button: true,
          label:
              'Puntos Eco: ${e.puntos} de $kMetaPuntosEco. Toca para ver el detalle',
          child: Material(
            color: Colors.white.withValues(alpha: 0.16),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PuntosEcoScreen()),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WaterFillCircle(
                        size: 28,
                        progress: e.progreso,
                        waterColor: Colors.white,
                        trackColor: Colors.white.withValues(alpha: 0.2),
                        borderColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.puntos}/$kMetaPuntosEco',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (e.pasajesGratis > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.card_giftcard,
                          size: 16,
                          color: Color(0xFFFFC933),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
