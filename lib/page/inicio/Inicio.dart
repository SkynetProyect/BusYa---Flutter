import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/page/inicio/componentes/TopBar.dart';
import 'package:flutter_application_1/service/determinePosition.dart'
    show determinePosition;
import 'package:flutter_application_1/service/rest/bus/BusService.dart'
    show BusService;
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

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

  final flutter_map.MapController _mapController = flutter_map.MapController();

  List<Empresa> _empresas = [];
  List<Ruta> _rutasDeEmpresa = [];

  Empresa? _empresaSeleccionada;
  Ruta? _rutaSeleccionada;

  List<flutter_map.Polyline> _polylines = [];
  List<flutter_map.Marker> _busMarkers = [];

  bool _loadingSelectores = true;
  String? _selectorError;
  Timer? _busTimer;
  bool _busRequestInFlight = false;
  StreamSubscription<Position>? _positionSubscription;
  latlong.LatLng? _userPosition;
  bool _centerOnUserLocation = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
    _cargarUbicacion();
  }

  @override
  void dispose() {
    _busTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarUbicacion() async {
    try {
      final position = await determinePosition();
      if (!mounted) return;
      _actualizarUbicacion(position);
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_actualizarUbicacion);
    } catch (_) {
      // La pantalla sigue funcionando aunque el usuario no conceda ubicación.
    }
  }

  void _actualizarUbicacion(Position position) {
    if (!mounted) return;

    final location = latlong.LatLng(position.latitude, position.longitude);
    setState(() => _userPosition = location);

    if (_centerOnUserLocation) {
      _centerOnUserLocation = false;
      _mapController.move(location, 15);
    }
  }

  Future<void> _cargarEmpresas() async {
    try {
      final empresas = await _empresaService.getAll();
      if (!mounted) return;
      setState(() {
        _empresas = empresas;
        _selectorError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _selectorError = error.toString());
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
      if (!mounted) return;
      setState(() => _rutasDeEmpresa = rutas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _selectorError = 'No se pudieron cargar las rutas');
    }
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
    if (!mounted || _rutaSeleccionada?.id != ruta.id) return;

    _busTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _actualizarBuses();
    });
  }

  void _dibujarPolyline(Ruta ruta) {
    if (ruta.encodedPolyline == null || ruta.encodedPolyline!.isEmpty) return;

    final points = _decodePolyline(ruta.encodedPolyline!);
    if (points.isEmpty) return;

    setState(() {
      _polylines = [
        flutter_map.Polyline(
          points: points,
          color: const Color(0xFF2E7D5B),
          strokeWidth: 4,
        ),
      ];
    });

    _ajustarCamara(points);
  }

  Future<void> _actualizarBuses() async {
    final routeId = _rutaSeleccionada?.id;
    if (routeId == null || _busRequestInFlight) return;

    _busRequestInFlight = true;
    try {
      final buses = await _busService.getByRutaId(routeId);
      if (!mounted || _rutaSeleccionada?.id != routeId) return;

      final nuevosMarkers = <flutter_map.Marker>[];
      for (final bus in buses) {
        if (bus.latitudActual == null || bus.longitudActual == null) continue;

        nuevosMarkers.add(
          flutter_map.Marker(
            point: latlong.LatLng(bus.latitudActual!, bus.longitudActual!),
            width: 44,
            height: 44,
            child: Tooltip(
              message: '${bus.placa}: ${_textoOcupacion(bus.nivelOcupacion)}',
              child: Icon(
                Icons.directions_bus,
                color: _colorDeOcupacion(bus.nivelOcupacion),
                size: 30,
              ),
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _busMarkers = nuevosMarkers;
      });
    } catch (_) {
      // si falla una actualización puntual, no interrumpimos el polling
    } finally {
      _busRequestInFlight = false;
    }
  }

  Color _colorDeOcupacion(String? nivel) {
    switch (nivel) {
      case 'ROJO':
        return Colors.red;
      case 'NARANJA':
        return Colors.orange;
      case 'VERDE':
      default:
        return Colors.green;
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

  Future<void> _ajustarCamara(List<latlong.LatLng> points) async {
    if (points.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 200));
    _mapController.fitCamera(
      flutter_map.CameraFit.bounds(
        bounds: flutter_map.LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  List<latlong.LatLng> _decodePolyline(String encoded) {
    List<latlong.LatLng> points = [];
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

      points.add(latlong.LatLng(lat / 1e5, lng / 1e5));
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
              flutter_map.FlutterMap(
                mapController: _mapController,
                options: const flutter_map.MapOptions(
                  initialCenter: latlong.LatLng(6.2442, -75.5812),
                  initialZoom: 12,
                ),
                children: [
                  flutter_map.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_application_1',
                  ),
                  flutter_map.PolylineLayer(polylines: _polylines),
                  flutter_map.MarkerLayer(
                    markers: [
                      ..._busMarkers,
                      if (_userPosition != null)
                        flutter_map.Marker(
                          point: _userPosition!,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const flutter_map.RichAttributionWidget(
                    attributions: [
                      flutter_map.TextSourceAttribution('OpenStreetMap'),
                    ],
                  ),
                ],
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
          : _selectorError != null
          ? Row(
              children: [
                const Expanded(
                  child: Text('No se pudieron cargar empresas y rutas'),
                ),
                IconButton(
                  tooltip: 'Reintentar',
                  onPressed: () {
                    setState(() {
                      _loadingSelectores = true;
                      _selectorError = null;
                    });
                    _cargarEmpresas();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Empresa>(
                      isExpanded: true,
                      hint: Text(
                        _empresas.isEmpty
                            ? 'Sin empresas disponibles'
                            : 'Empresa',
                      ),
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
                      hint: Text(
                        _empresaSeleccionada == null
                            ? 'Selecciona una empresa'
                            : (_rutasDeEmpresa.isEmpty
                                  ? 'Sin rutas disponibles'
                                  : 'Ruta'),
                      ),
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
