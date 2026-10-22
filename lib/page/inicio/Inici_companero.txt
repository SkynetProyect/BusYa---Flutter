import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Bus.dart' show Bus;
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/page/inicio/alerts/BusProximityAlertService.dart'
    show BusProximityAlertService;
import 'package:flutter_application_1/page/inicio/componentes/BusInfoSheet.dart'
    show BusInfoSheet;
import 'package:flutter_application_1/page/inicio/componentes/BusMarkerIcon.dart';
import 'package:flutter_application_1/page/inicio/componentes/OccupancyFormater.dart'
    show OccupancyFormatter;
import 'package:flutter_application_1/page/inicio/componentes/PeriodicPooler.dart'
    show PeriodicPoller;
import 'package:flutter_application_1/page/inicio/componentes/PolylineDecoder.dart'
    show PolylineDecoder;
import 'package:flutter_application_1/page/inicio/componentes/RouteSelectorBar.dart';
import 'package:flutter_application_1/page/inicio/componentes/TopBar.dart';
import 'package:flutter_application_1/page/inicio/componentes/UserLocationMaker.dart'
    show UserLocationMarker;
import 'package:flutter_application_1/page/inicio/persistence/SelectionStorageService.dart'
    show SelectionStorageService;
import 'package:flutter_application_1/service/CompassService.dart'
    show CompassService;
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

/// Pantalla principal: mapa con ruta seleccionada, buses en tiempo real,
/// ubicación/orientación del usuario y alertas de proximidad.
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with WidgetsBindingObserver {
  // ───────────── Constantes
  static const Duration _busPollInterval = Duration(seconds: 2);
  static const latlong.LatLng _defaultCenter = latlong.LatLng(6.2442, -75.5812);

  // ───────────── Servicios (cada uno con una única responsabilidad)
  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();
  final BusService _busService = BusService();
  final SelectionStorageService _selectionStorage = SelectionStorageService();
  final CompassService _compass = CompassService();
  final BusProximityAlertService _alertService = BusProximityAlertService();
  final PeriodicPoller _busPoller = PeriodicPoller();

  final flutter_map.MapController _mapController = flutter_map.MapController();

  // ───────────── Estado de selección
  List<Empresa> _empresas = [];
  List<Ruta> _rutasDeEmpresa = [];
  Empresa? _empresaSeleccionada;
  Ruta? _rutaSeleccionada;
  bool _loadingSelectores = true;
  String? _selectorError;

  // ───────────── Estado del mapa
  List<flutter_map.Polyline> _polylines = [];
  List<flutter_map.Marker> _busMarkers = [];
  bool _busRequestInFlight = false;

  // ───────────── Estado de ubicación
  StreamSubscription<Position>? _positionSubscription;
  latlong.LatLng? _userPosition;
  bool _centerOnUserLocation = true;

  // ═══════════════════════ Ciclo de vida ═══════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarSelectores(); // Carga empresas y restaura la selección guardada.
    _cargarUbicacion();
    _iniciarBrujula();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busPoller.stop();
    _positionSubscription?.cancel();
    _compass.dispose();
    _alertService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Pausa/reanuda sensores y polling según el estado de la app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _busPoller.stop();
        _positionSubscription?.pause();
        _compass.pause();
        break;
      case AppLifecycleState.resumed:
        _positionSubscription?.resume();
        _compass.resume();
        if (_rutaSeleccionada != null && !_busPoller.isRunning) {
          _iniciarPollingBuses(refrescarYa: true);
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Inicia la brújula; si falla o no existe, la app sigue funcionando.
  void _iniciarBrujula() {
    try {
      _compass.start();
    } catch (e) {
      debugPrint('[COMPASS] no se pudo iniciar: $e');
    }
  }

  // ═══════════════════════ Ubicación ═══════════════════════

  /// Obtiene la posición inicial y se suscribe a los cambios.
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
            onError: (e) => debugPrint('[LOCATION] stream error: $e'),
            cancelOnError: false,
          );
    } catch (_) {
      // La pantalla sigue funcionando sin permiso de ubicación.
    }
  }

  /// Guarda la posición del usuario y centra el mapa la primera vez
  /// (salvo que ya haya una ruta encuadrada).
  void _actualizarUbicacion(Position position) {
    if (!mounted) return;
    final location = latlong.LatLng(position.latitude, position.longitude);
    setState(() => _userPosition = location);

    if (_centerOnUserLocation) {
      _centerOnUserLocation = false;
      _mapController.move(location, 15);
    }
  }

  // ═══════════════════════ Selección Empresa / Ruta ═══════════════════════

  /// Carga empresas y luego restaura la última selección persistida.
  Future<void> _cargarSelectores() async {
    try {
      final empresas = await _empresaService.getAll();
      if (!mounted) return;
      setState(() {
        _empresas = empresas;
        _selectorError = null;
      });
      await _restaurarSeleccion();
    } catch (error) {
      if (!mounted) return;
      setState(() => _selectorError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingSelectores = false);
    }
  }

  /// Reaplica la Empresa/Ruta guardadas (si siguen existiendo).
  Future<void> _restaurarSeleccion() async {
    try {
      final saved = await _selectionStorage.load();
      debugPrint('[SELECTION] restaurando: $saved');
      if (saved.empresaId == null) return;

      final empresa = _empresas
          .where((e) => e.id == saved.empresaId)
          .firstOrNull;
      if (empresa == null) {
        debugPrint('[SELECTION] empresa ${saved.empresaId} no existe en lista');
        return;
      }

      await _seleccionarEmpresa(empresa, persistir: false);
      if (!mounted || saved.rutaId == null) return;

      final ruta = _rutasDeEmpresa
          .where((r) => r.id == saved.rutaId)
          .firstOrNull;
      if (ruta == null) {
        debugPrint('[SELECTION] ruta ${saved.rutaId} no existe en lista');
        return;
      }

      await _seleccionarRuta(ruta, persistir: false);
    } catch (e) {
      // Un fallo al restaurar nunca debe mostrar el error de carga.
      debugPrint('[SELECTION] error restaurando: $e');
    }
  }

  /// Persiste la selección actual.
  Future<void> _guardarSeleccion() => _selectionStorage.save(
    empresaId: _empresaSeleccionada?.id,
    rutaId: _rutaSeleccionada?.id,
  );

  /// Acción del usuario sobre el dropdown de empresa.
  Future<void> _onEmpresaSeleccionada(Empresa? empresa) =>
      _seleccionarEmpresa(empresa);

  /// Acción del usuario sobre el dropdown de ruta.
  Future<void> _onRutaSeleccionada(Ruta? ruta) => _seleccionarRuta(ruta);

  /// Selecciona una empresa, limpia el mapa y carga sus rutas.
  Future<void> _seleccionarEmpresa(
    Empresa? empresa, {
    bool persistir = true,
  }) async {
    _detenerPollingBuses();
    setState(() {
      _empresaSeleccionada = empresa;
      _rutaSeleccionada = null;
      _rutasDeEmpresa = [];
      _limpiarMapa();
    });
    if (persistir) await _guardarSeleccion();

    if (empresa?.id == null) return;
    try {
      final rutas = await _rutaService.getByEmpresaId(empresa!.id!);
      if (!mounted || _empresaSeleccionada?.id != empresa.id) return;
      setState(() => _rutasDeEmpresa = rutas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _selectorError = 'No se pudieron cargar las rutas');
    }
  }

  /// Selecciona una ruta: dibuja su trazado e inicia el seguimiento de buses.
  Future<void> _seleccionarRuta(Ruta? ruta, {bool persistir = true}) async {
    _detenerPollingBuses();
    _alertService.reset();
    setState(() {
      _rutaSeleccionada = ruta;
      _limpiarMapa();
    });
    if (persistir) await _guardarSeleccion();
    if (ruta == null) return;

    _dibujarPolyline(ruta);
    await _actualizarBuses(); // Primera carga inmediata.
    if (!mounted || _rutaSeleccionada?.id != ruta.id) return;

    _iniciarPollingBuses();
  }

  /// Borra polylines y marcadores de buses del mapa.
  void _limpiarMapa() {
    _polylines = [];
    _busMarkers = [];
  }

  // ═══════════════════════ Mapa: ruta y buses ═══════════════════════

  /// Dibuja el trazado de la ruta y encuadra la cámara sobre él.
  void _dibujarPolyline(Ruta ruta) {
    final encoded = ruta.encodedPolyline;
    if (encoded == null || encoded.isEmpty) return;

    final points = PolylineDecoder.decode(encoded);
    if (points.isEmpty) return;

    // La ruta tiene prioridad sobre el centrado inicial en el usuario.
    _centerOnUserLocation = false;

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

  /// Encuadra la cámara para mostrar todos los [points].
  Future<void> _ajustarCamara(List<latlong.LatLng> points) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _mapController.fitCamera(
      flutter_map.CameraFit.bounds(
        bounds: flutter_map.LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  /// Inicia el polling periódico de buses.
  void _iniciarPollingBuses({bool refrescarYa = false}) {
    if (refrescarYa) _actualizarBuses();
    _busPoller.start(_busPollInterval, _actualizarBuses);
  }

  /// Detiene el polling de buses.
  void _detenerPollingBuses() => _busPoller.stop();

  /// Consulta los buses de la ruta activa, evalúa alertas y refresca marcadores.
  Future<void> _actualizarBuses() async {
    if (!mounted) return;
    final routeId = _rutaSeleccionada?.id;
    if (routeId == null || _busRequestInFlight) return;

    _busRequestInFlight = true;
    try {
      final buses = await _busService.getByRutaId(routeId);
      if (!mounted || _rutaSeleccionada?.id != routeId) return;

      final markers = <flutter_map.Marker>[];
      final activeIds = <int>{};

      for (final bus in buses) {
        if (bus.latitudActual == null || bus.longitudActual == null) continue;
        final busPos = latlong.LatLng(bus.latitudActual!, bus.longitudActual!);
        if (bus.id != null) activeIds.add(bus.id!);

        _evaluarAlerta(bus, busPos);
        markers.add(_construirMarkerBus(bus, busPos));
      }

      _alertService.retainOnly(activeIds);
      setState(() => _busMarkers = markers);
    } catch (_) {
      // Un fallo puntual no debe interrumpir el polling.
    } finally {
      _busRequestInFlight = false;
    }
  }

  /// Evalúa proximidad del bus y muestra el aviso en pantalla si aplica.
  void _evaluarAlerta(Bus bus, latlong.LatLng busPos) {
    final user = _userPosition;
    if (user == null) return;

    if (_alertService.evaluate(bus, busPos, user) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El bus ${bus.placa} está cerca de ti'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Crea el marcador de un bus.
  flutter_map.Marker _construirMarkerBus(Bus bus, latlong.LatLng pos) {
    return flutter_map.Marker(
      point: pos,
      width: 44,
      height: 44,
      child: BusMarkerIcon(bus: bus, onTap: () => _mostrarInfoBus(bus)),
    );
  }

  /// Marcador del usuario (flecha con brújula o punto sin ella).
  flutter_map.Marker _construirMarkerUsuario(latlong.LatLng pos) {
    return flutter_map.Marker(
      point: pos,
      width: 44,
      height: 44,
      child: UserLocationMarker(heading: _compass.heading),
    );
  }

  /// Muestra el detalle del bus en un bottom sheet.
  void _mostrarInfoBus(Bus bus) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BusInfoSheet(
        bus: bus,
        markerColor: OccupancyFormatter.color(bus.nivelOcupacion),
        ocupacionTexto: OccupancyFormatter.label(bus.nivelOcupacion),
        rutaNombre: _rutaSeleccionada?.nombre,
      ),
    );
  }

  // ═══════════════════════ UI ═══════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMap(),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: RouteSelectorBar(
                  loading: _loadingSelectores,
                  error: _selectorError,
                  empresas: _empresas,
                  rutas: _rutasDeEmpresa,
                  empresaSeleccionada: _empresaSeleccionada,
                  rutaSeleccionada: _rutaSeleccionada,
                  onEmpresaChanged: _onEmpresaSeleccionada,
                  onRutaChanged: _onRutaSeleccionada,
                  onRetry: () {
                    setState(() {
                      _loadingSelectores = true;
                      _selectorError = null;
                    });
                    _cargarSelectores();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mapa con tiles, ruta, buses y marcador del usuario.
  Widget _buildMap() {
    return flutter_map.FlutterMap(
      mapController: _mapController,
      options: const flutter_map.MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 12,
      ),
      children: [
        flutter_map.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_application_1',
        ),
        flutter_map.PolylineLayer(polylines: _polylines),
        flutter_map.MarkerLayer(
          markers: [
            ..._busMarkers,
            if (_userPosition != null) _construirMarkerUsuario(_userPosition!),
          ],
        ),
        const flutter_map.RichAttributionWidget(
          attributions: [flutter_map.TextSourceAttribution('OpenStreetMap')],
        ),
      ],
    );
  }
}
