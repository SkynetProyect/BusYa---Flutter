import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import '../../service/puntos_service.dart';

class PuntosEcoScreen extends StatefulWidget {
  const PuntosEcoScreen({super.key});

  @override
  State<PuntosEcoScreen> createState() => _PuntosEcoScreenState();
}

class _PuntosEcoScreenState extends State<PuntosEcoScreen> {
  final PuntosService _puntosService = PuntosService();
  int _puntos = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPuntos();
  }

  Future<void> _cargarPuntos() async {
    setState(() => _cargando = true);
    try {
      final puntos = await _puntosService.obtenerPuntos();
      if (mounted) {
        setState(() {
          _puntos = puntos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const metaPuntos = 30;
    final progreso = (_puntos / metaPuntos).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Puntos Eco'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _cargarPuntos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta Principal de Balance
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.eco, color: Colors.lightGreenAccent, size: 48),
                          const SizedBox(height: 10),
                          const Text(
                            'Puntos Eco Acumulados',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_puntos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$_puntos de $metaPuntos puntos para tu próximo pasaje gratis',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estado cuando el balance es 0
                    if (_puntos == 0)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.45)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryLight),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aún no tienes puntos. ¡Realiza tu primer viaje con BusYa para empezar a sumar!',
                                style: TextStyle(color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Sección de Información y Reglas
                    const Text(
                      '¿Cómo funciona el programa?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoTile(
                      icon: Icons.directions_bus,
                      title: '1 Punto por cada viaje',
                      subtitle: 'Al validar tu pasaje en el validador NFC de cualquier bus del sistema.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      icon: Icons.card_giftcard,
                      title: 'Pasaje gratuito',
                      subtitle: 'Al acumular 30 puntos obtienes un pasaje 100% bonificado en tu billetera.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      icon: Icons.park,
                      title: 'Impacto ambiental',
                      subtitle: 'Incentivamos la movilidad masiva para reducir emisiones en el Valle de Aburrá.',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(icon, color: AppColors.primaryLight),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ),
    );
  }
}
