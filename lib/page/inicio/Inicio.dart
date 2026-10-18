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
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pantalla principal: mapa con ruta seleccionada, buses en tiempo real
/// (Supabase Realtime Broadcast), ubicación/orientación del usuario y
/// alertas de proximidad.
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with WidgetsBindingObserver {
  // ───────────── Constantes
  static const String _busChannelName = 'seguimiento-buses';
  static const String _busEventName = 'posicion_bus';
  static const Duration _renderThrottle = Duration(milliseconds: 250);
  static const latlong.LatLng _defaultCenter = latlong.LatLng(6.2442, -75.5812);

  // ───────────── Servicios
  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();
  final BusService _busService = BusService();
  final SelectionStorageService _selectionStorage = SelectionStorageService();
  final CompassService _compass = CompassService();
  final BusProximityAlertService _alertService = BusProximityAlertService();

  SupabaseClient get _supabase => Supabase.instance.client;

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

  /// Último estado conocido de cada bus de la ruta activa (id -> Bus).
  /// Se siembra con un snapshot REST y se actualiza con los broadcasts.
  final Map<int, Bus> _busesPorId = {};
  RealtimeChannel? _busChannel;
  Timer? _renderTimer;

  // ───────────── Estado de ubicación
  StreamSubscription<Position>? _positionSubscription;
  latlong.LatLng? _userPosition;
  bool _centerOnUserLocation = true;

  // ═══════════════════════ Ciclo de vida ═══════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarSelectores();
    _cargarUbicacion();
    _iniciarBrujula();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _renderTimer?.cancel();
    unawaited(_cancelarSuscripcionBuses());
    _positionSubscription?.cancel();
    _compass.dispose();
    _alertService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Pausa/reanuda sensores y suscripción realtime según el estado de la app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        unawaited(_cancelarSuscripcionBuses());
        _positionSubscription?.pause();
        _compass.pause();
        break;
      case AppLifecycleState.resumed:
        _positionSubscription?.resume();
        _compass.resume();
        final ruta = _rutaSeleccionada;
        if (ruta != null && _busChannel == null) {
          _iniciarSeguimientoBuses(ruta);
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _iniciarBrujula() {
    try {
      _compass.start();
    } catch (e) {
      debugPrint('[COMPASS] no se pudo iniciar: $e');
    }
  }

  // ═══════════════════════ Ubicación ═══════════════════════

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

  void _actualizarUbicacion(Position position) {
    if (!mounted) return;
    final location = latlong.LatLng(position.latitude, position.longitude);
    setState(() => _userPosition = location);

    if (_centerOnUserLocation) {
      _centerOnUserLocation = false;
      _mapController.move(location, 15);
    }
  }

  /// Centra el mapa en la posición del usuario (botón "Mi ubicación").
  /// Mantiene el zoom actual si ya es cercano; si no, acerca a 15.
  Future<void> _centrarEnUsuario() async {
    var pos = _userPosition;

    if (pos == null) {
      // Aún sin ubicación: intentar obtenerla ahora.
      try {
        final position = await determinePosition();
        if (!mounted) return;
        _actualizarUbicacion(position);
        pos = _userPosition;
      } catch (_) {}
    }

    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo obtener tu ubicación. Revisa los permisos.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final zoom = _mapController.camera.zoom;
    _mapController.move(pos, zoom < 15 ? 15 : zoom);
  }

  // ═══════════════════════ Selección Empresa / Ruta ═══════════════════════

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
      debugPrint('[SELECTION] error restaurando: $e');
    }
  }

  Future<void> _guardarSeleccion() => _selectionStorage.save(
    empresaId: _empresaSeleccionada?.id,
    rutaId: _rutaSeleccionada?.id,
  );

  Future<void> _onEmpresaSeleccionada(Empresa? empresa) =>
      _seleccionarEmpresa(empresa);

  Future<void> _onRutaSeleccionada(Ruta? ruta) => _seleccionarRuta(ruta);

  Future<void> _seleccionarEmpresa(
    Empresa? empresa, {
    bool persistir = true,
  }) async {
    await _detenerSeguimientoBuses();
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

  /// Selecciona una ruta: dibuja su trazado e inicia el seguimiento realtime.
  Future<void> _seleccionarRuta(Ruta? ruta, {bool persistir = true}) async {
    await _detenerSeguimientoBuses();
    _alertService.reset();
    setState(() {
      _rutaSeleccionada = ruta;
      _limpiarMapa();
    });
    if (persistir) await _guardarSeleccion();
    if (ruta == null) return;

    _dibujarPolyline(ruta);
    await _iniciarSeguimientoBuses(ruta);
  }

  void _limpiarMapa() {
    _polylines = [];
    _busMarkers = [];
    _busesPorId.clear();
  }

  // ═══════════════════════ Mapa: ruta ═══════════════════════

  void _dibujarPolyline(Ruta ruta) {
    final encoded = ruta.encodedPolyline;
    if (encoded == null || encoded.isEmpty) return;

    final points = PolylineDecoder.decode(encoded);
    if (points.isEmpty) return;

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

  // ═══════════════════════ Buses en tiempo real ═══════════════════════

  /// 1) Snapshot REST (última posición guardada en BD, para pintar ya).
  /// 2) Suscripción al canal Broadcast para los movimientos en vivo.
  Future<void> _iniciarSeguimientoBuses(Ruta ruta) async {
    final routeId = ruta.id;
    if (routeId == null) return;

    // Suscribirse primero para no perder mensajes mientras llega el snapshot.
    await _suscribirBuses(routeId);
    await _cargarSnapshotBuses(routeId);
  }

  Future<void> _suscribirBuses(int routeId) async {
    await _cancelarSuscripcionBuses();

    final channel = _supabase.channel(_busChannelName);
    channel
        .onBroadcast(
          event: _busEventName,
          callback: (payload) => _onBroadcast(routeId, payload),
        )
        .subscribe((status, error) {
          debugPrint('[REALTIME] $status ${error ?? ''}');
        });
    _busChannel = channel;
  }

  Future<void> _cancelarSuscripcionBuses() async {
    final channel = _busChannel;
    _busChannel = null;
    if (channel != null) {
      try {
        await _supabase.removeChannel(channel);
      } catch (e) {
        debugPrint('[REALTIME] error cerrando canal: $e');
      }
    }
  }

  Future<void> _detenerSeguimientoBuses() async {
    _renderTimer?.cancel();
    await _cancelarSuscripcionBuses();
  }

  /// Carga la última posición persistida de los buses de la ruta.
  Future<void> _cargarSnapshotBuses(int routeId) async {
    try {
      final buses = await _busService.getByRutaId(routeId);
      if (!mounted || _rutaSeleccionada?.id != routeId) return;

      for (final bus in buses) {
        final id = bus.id;
        if (id == null) continue;
        // No pisar un dato en vivo más reciente con el snapshot.
        _busesPorId.putIfAbsent(id, () => bus);
        final lat = bus.latitudActual;
        final lng = bus.longitudActual;
        if (lat != null && lng != null) {
          _evaluarAlerta(bus, latlong.LatLng(lat, lng));
        }
      }
      _renderizarBuses();
    } catch (e) {
      debugPrint('[BUSES] snapshot falló: $e');
    }
  }

  /// Maneja un mensaje Broadcast. Acepta:
  ///  - lote:   { buses: [ {id_bus, ...}, ... ] }
  ///  - simple: { id_bus, latitud, longitud, nivel_ocupacion, ... }
  void _onBroadcast(int routeId, Map<String, dynamic> message) {
    if (!mounted || _rutaSeleccionada?.id != routeId) return;

    // Según la versión del SDK el payload llega envuelto en 'payload'.
    final inner = message['payload'];
    final data = Map<String, dynamic>.from(inner is Map ? inner : message);

    final items = data['buses'] is List ? data['buses'] as List : [data];

    var changed = false;
    for (final item in items) {
      if (item is! Map) continue;
      if (_aplicarPosicion(routeId, Map<String, dynamic>.from(item))) {
        changed = true;
      }
    }
    if (changed) _programarRender();
  }

  /// Aplica una posición al estado local. Devuelve true si hubo cambios.
  bool _aplicarPosicion(int routeId, Map<String, dynamic> m) {
    final idRuta = (m['id_ruta'] as num?)?.toInt();
    final idBus = (m['id_bus'] as num?)?.toInt();
    final lat = (m['latitud'] as num?)?.toDouble();
    final lng = (m['longitud'] as num?)?.toDouble();
    if (idBus == null || lat == null || lng == null) return false;
    if (idRuta != null && idRuta != routeId) return false; // otra ruta

    final actual = _busesPorId[idBus];
    if (actual == null) return false; // bus que no está en el snapshot

    final actualizado = actual.copyWith(
      latitudActual: lat,
      longitudActual: lng,
      nivelOcupacion:
          (m['nivel_ocupacion'] as String?) ?? actual.nivelOcupacion,
      ultimaActualizacionGps:
          DateTime.tryParse(m['timestamp']?.toString() ?? '') ??
          actual.ultimaActualizacionGps,
    );
    _busesPorId[idBus] = actualizado;
    _evaluarAlerta(actualizado, latlong.LatLng(lat, lng));
    return true;
  }

  /// Agrupa varias actualizaciones en un único setState.
  void _programarRender() {
    if (_renderTimer?.isActive ?? false) return;
    _renderTimer = Timer(_renderThrottle, () {
      if (mounted) _renderizarBuses();
    });
  }

  void _renderizarBuses() {
    if (!mounted) return;
    final markers = <flutter_map.Marker>[];
    for (final bus in _busesPorId.values) {
      final lat = bus.latitudActual;
      final lng = bus.longitudActual;
      if (lat == null || lng == null) continue;
      markers.add(_construirMarkerBus(bus, latlong.LatLng(lat, lng)));
    }
    _alertService.retainOnly(_busesPorId.keys.toSet());
    setState(() => _busMarkers = markers);
  }

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

  flutter_map.Marker _construirMarkerBus(Bus bus, latlong.LatLng pos) {
    return flutter_map.Marker(
      point: pos,
      width: 44,
      height: 44,
      child: BusMarkerIcon(bus: bus, onTap: () => _mostrarInfoBus(bus)),
    );
  }

  flutter_map.Marker _construirMarkerUsuario(latlong.LatLng pos) {
    return flutter_map.Marker(
      point: pos,
      width: 44,
      height: 44,
      child: UserLocationMarker(heading: _compass.heading),
    );
  }

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
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'btn_centrar_usuario',
                  tooltip: 'Mi ubicación',
                  onPressed: _centrarEnUsuario,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
