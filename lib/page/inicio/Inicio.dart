import 'package:audioplayers/audioplayers.dart' show AudioPlayer, AssetSource;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/page/inicio/componentes/TopBar.dart';
import 'package:flutter_application_1/service/determinePosition.dart'
    show determinePosition;
import 'package:flutter_application_1/service/notification_service.dart'
    show NotificationService;

import 'package:flutter_application_1/service/rest/bus/BusService.dart'
    show BusService;
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_application_1/model/Bus.dart' show Bus;
import 'package:flutter_application_1/page/inicio/componentes/BusInfoSheet.dart'
    show BusInfoSheet;

import 'dart:async';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with WidgetsBindingObserver {
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

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<int> _busesAlertados =
      {}; // ids de buses ya alertados en este acercamiento
  static const double _distanciaAlertaMetros = 1000; // ajusta según necesites

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarEmpresas();
    _cargarUbicacion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busTimer?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _busTimer?.cancel();
        _busTimer = null;
        _positionSubscription?.pause();
        break;
      case AppLifecycleState.resumed:
        _positionSubscription?.resume();
        if (_rutaSeleccionada != null && _busTimer == null) {
          _actualizarBuses(); // refresca inmediatamente al volver
          _busTimer = Timer.periodic(const Duration(seconds: 2), (_) {
            _actualizarBuses();
          });
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  double _distanciaMetros(latlong.LatLng a, latlong.LatLng b) {
    const distance = latlong.Distance();
    return distance.as(latlong.LengthUnit.Meter, a, b);
  }

  Future<void> _reproducirAlerta() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/bus_alert.mp3'));
    } catch (_) {
      // si falla el audio no debe romper la app
    }
  }

  Future<void> _cargarUbicacion() async {
    try {
      final position = await determinePosition();
      if (!mounted) return;
      _actualizarUbicacion(position);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            _actualizarUbicacion,
            onError: (error) {
              debugPrint('[LOCATION DEBUG] stream error: $error');
              // no relanzamos, simplemente lo ignoramos para no romper la UI
            },
            cancelOnError: false,
          );
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

    debugPrint(
      '[ROUTE DEBUG] selected route -> id=${ruta.id}, idEmpresa=${ruta.idEmpresa}, nombre=${ruta.nombre}, precio=${ruta.precioPasaje}, polylineLength=${ruta.encodedPolyline?.length ?? 0}',
    );

    _dibujarPolyline(ruta);
    await _actualizarBuses(); // primera carga inmediata
    if (!mounted || _rutaSeleccionada?.id != ruta.id) return;

    _busTimer = Timer.periodic(const Duration(seconds: 2), (_) {
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
    if (!mounted) return;
    final routeId = _rutaSeleccionada?.id;
    if (routeId == null || _busRequestInFlight) return;

    _busRequestInFlight = true;
    try {
      final buses = await _busService.getByRutaId(routeId);
      if (!mounted || _rutaSeleccionada?.id != routeId) return;

      final nuevosMarkers = <flutter_map.Marker>[];
      final busesActualesIds = <int>{};

      for (final bus in buses) {
        if (bus.latitudActual == null || bus.longitudActual == null) continue;

        final busPos = latlong.LatLng(bus.latitudActual!, bus.longitudActual!);
        if (bus.id != null) busesActualesIds.add(bus.id!);
        // --- Alerta de proximidad ---
        if (bus.id != null && _userPosition != null) {
          final distancia = _distanciaMetros(_userPosition!, busPos);
          final yaAlertado = _busesAlertados.contains(bus.id);

          if (distancia <= _distanciaAlertaMetros && !yaAlertado) {
            _busesAlertados.add(bus.id!);
            _reproducirAlerta();

            NotificationService().mostrarNotificacion(
              id: bus.id!,
              titulo: 'Bus cerca de ti',
              cuerpo:
                  'El bus ${bus.placa} está a menos de ${_distanciaAlertaMetros.toInt()} metros',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('El bus ${bus.placa} está cerca de ti'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else if (distancia > _distanciaAlertaMetros && yaAlertado) {
            // si se aleja de nuevo, permite re-alertar en un futuro acercamiento
            _busesAlertados.remove(bus.id);
          }
        }

        nuevosMarkers.add(
          flutter_map.Marker(
            point: busPos,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showBusInfo(bus),
              child: Tooltip(
                message:
                    '${bus.placa}: ${_textoPorcentaje(bus.nivelOcupacion)}',
                child: Icon(
                  Icons.directions_bus,
                  color: _colorDeOcupacion(bus.nivelOcupacion),
                  size: 30,
                ),
              ),
            ),
          ),
        );
      }

      // limpia alertas de buses que ya no están en la ruta
      _busesAlertados.removeWhere((id) => !busesActualesIds.contains(id));

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

  void _showBusInfo(Bus bus) {
    if (!mounted) return;
    final color = _colorDeOcupacion(bus.nivelOcupacion);
    final ocupacion = _textoPorcentaje(bus.nivelOcupacion);
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BusInfoSheet(
        bus: bus,
        markerColor: color,
        ocupacionTexto: ocupacion,
        rutaNombre: _rutaSeleccionada?.nombre,
      ),
    );
  }

  String _textoPorcentaje(String? nivel) {
    final parsed = _parseOccupancyRatio(nivel);
    if (parsed != null) {
      if (parsed > 0.8) return 'Lleno';
      if (parsed > 0.6) return 'Moderado';
      return 'Vacío';
    }

    switch (nivel?.toUpperCase()) {
      case 'ROJO':
        return 'Lleno';
      case 'NARANJA':
        return 'Moderado';
      case 'VERDE':
      default:
        return 'Vacío';
    }
  }

  Color _colorDeOcupacion(String? nivel) {
    final parsed = _parseOccupancyRatio(nivel);
    if (parsed != null) {
      if (parsed > 0.8) return Colors.red;
      if (parsed > 0.6) return Colors.orange;
      return Colors.green;
    }

    switch (nivel?.toUpperCase()) {
      case 'ROJO':
        return Colors.red;
      case 'NARANJA':
        return Colors.orange;
      case 'VERDE':
      default:
        return Colors.green;
    }
  }

  // Intenta extraer un ratio [0..1] a partir de una cadena como
  // "50%", "0.5", "75 %", etc. Devuelve null si no es interpretable.
  double? _parseOccupancyRatio(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Si contiene un número, extraerlo
    final numberMatch = RegExp(r"([0-9]+(?:[.,][0-9]+)?)").firstMatch(s);
    if (numberMatch == null) return null;
    final numStr = numberMatch.group(1)!.replaceAll(',', '.');
    final value = double.tryParse(numStr);
    if (value == null) return null;

    // Si hay un porcentaje explícito, interpretarlo como 0..100
    if (s.contains('%')) {
      return (value.clamp(0, 100)) / 100.0;
    }

    // Sin %, si el valor está en 0..1, tómalo como ratio; si > 1, asume porcentaje 0..100
    if (value <= 1.0) return value.clamp(0.0, 1.0);
    return (value.clamp(0.0, 100.0)) / 100.0;
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
