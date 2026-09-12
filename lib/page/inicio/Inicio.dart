import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/page/inicio/componentes/TopBar.dart';
import 'package:flutter_application_1/service/rest/bus/BusService.dart'
    show BusService;
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:async';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();
  final BusService _busService = BusService();

  GoogleMapController? _mapController;

  List<Empresa> _empresas = [];
  List<Ruta> _rutasDeEmpresa = [];

  Empresa? _empresaSeleccionada;
  Ruta? _rutaSeleccionada;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _busMarkers = {};

  bool _loadingSelectores = true;
  Timer? _busTimer;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  @override
  void dispose() {
    _busTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final empresas = await _empresaService.getAll();
      setState(() => _empresas = empresas);
    } catch (_) {
      // el servicio ya muestra el popup
    } finally {
      if (mounted) setState(() => _loadingSelectores = false);
    }
  }

  Future<void> _onEmpresaSeleccionada(Empresa? empresa) async {
    _busTimer?.cancel();
    setState(() {
      _empresaSeleccionada = empresa;
      _rutaSeleccionada = null;
      _rutasDeEmpresa = [];
      _polylines.clear();
      _busMarkers.clear();
    });

    if (empresa?.id == null) return;

    try {
      final rutas = await _rutaService.getByEmpresaId(empresa!.id!);
      setState(() => _rutasDeEmpresa = rutas);
    } catch (_) {}
  }

  Future<void> _onRutaSeleccionada(Ruta? ruta) async {
    _busTimer?.cancel();
    setState(() {
      _rutaSeleccionada = ruta;
      _polylines.clear();
      _busMarkers.clear();
    });

    if (ruta == null) return;

    _dibujarPolyline(ruta);
    await _actualizarBuses(); // primera carga inmediata
    _busTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _actualizarBuses();
    });
  }

  void _dibujarPolyline(Ruta ruta) {
    if (ruta.encodedPolyline == null || ruta.encodedPolyline!.isEmpty) return;

    final points = _decodePolyline(ruta.encodedPolyline!);
    if (points.isEmpty) return;

    setState(() {
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: PolylineId('ruta_${ruta.id}'),
            points: points,
            color: const Color(0xFF2E7D5B),
            width: 4,
          ),
        );
    });

    _ajustarCamara(points);
  }

  Future<void> _actualizarBuses() async {
    if (_rutaSeleccionada?.id == null) return;

    try {
      final buses = await _busService.getByRutaId(_rutaSeleccionada!.id!);

      final nuevosMarkers = <Marker>{};
      for (final bus in buses) {
        if (bus.latitudActual == null || bus.longitudActual == null) continue;

        nuevosMarkers.add(
          Marker(
            markerId: MarkerId('bus_${bus.id}'),
            position: LatLng(bus.latitudActual!, bus.longitudActual!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _hueDeOcupacion(bus.nivelOcupacion),
            ),
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: bus.placa,
              snippet: _textoOcupacion(bus.nivelOcupacion),
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _busMarkers
          ..clear()
          ..addAll(nuevosMarkers);
      });
    } catch (_) {
      // si falla una actualización puntual, no interrumpimos el polling
    }
  }

  double _hueDeOcupacion(String? nivel) {
    switch (nivel) {
      case 'ROJO':
        return BitmapDescriptor.hueRed;
      case 'NARANJA':
        return BitmapDescriptor.hueOrange;
      case 'VERDE':
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  String _textoOcupacion(String? nivel) {
    switch (nivel) {
      case 'ROJO':
        return 'Ocupación alta';
      case 'NARANJA':
        return 'Ocupación media';
      case 'VERDE':
        return 'Ocupación baja';
      default:
        return 'Sin datos de ocupación';
    }
  }

  Future<void> _ajustarCamara(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await Future.delayed(const Duration(milliseconds: 200));
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.2442, -75.5812), // Medellín
                  zoom: 12,
                ),
                onMapCreated: (controller) => _mapController = controller,
                polylines: _polylines,
                markers: _busMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildSelectores(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectores() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _loadingSelectores
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          : Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Empresa>(
                      isExpanded: true,
                      hint: const Text('Empresa'),
                      value: _empresaSeleccionada,
                      items: _empresas
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onEmpresaSeleccionada,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Ruta>(
                      isExpanded: true,
                      hint: const Text('Ruta'),
                      value: _rutaSeleccionada,
                      items: _rutasDeEmpresa
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _rutasDeEmpresa.isEmpty
                          ? null
                          : _onRutaSeleccionada,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
