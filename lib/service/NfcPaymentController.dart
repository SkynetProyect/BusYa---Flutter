import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../model/Tarjeta.dart';
import '../model/PagoNfcResult.dart';
import './nfc_service.dart';
import './puntos_service.dart';
import './rest/ruta_favorita/RutaFavoritaService.dart';
import './determinePosition.dart';
import '../model/RutaFavorita.dart';
import 'package:flutter_application_1/service/PaymentProcessorService.dart';
import 'PasajeEmergenciaState.dart';
import '../model/NfcUiState.dart';

class NfcPaymentController extends ChangeNotifier {
  NfcPaymentController({
    required this.idCliente,
    this.onPagoCompletado,
    this.onPasajeEcoGanado,
  });
  final String idCliente;
  final VoidCallback? onPagoCompletado; // refrescar saldos del carrusel

  /// Se llama cuando este viaje completó los 30 puntos Eco y se ganó un
  /// pasaje gratis. La pantalla decide cómo celebrarlo (EcoCelebraciones).
  final VoidCallback? onPasajeEcoGanado;

  final _payments = PaymentProcessorService();
  final _puntos = PuntosService();
  final _rutas = RutaFavoritaService();

  bool _disposed = false;
  Tarjeta? _tarjeta;
  Tarjeta? get tarjeta => _tarjeta;
  set tarjeta(Tarjeta? t) {
    if (_tarjeta?.id == t?.id && (_tarjeta != null) == (t != null)) return;
    _tarjeta = t;
    // El carrusel puede llamar esto durante el build; se notifica después del frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _resetTimer?.cancel();
    super.dispose();
  }

  NfcUiState state = NfcUiState.idle;
  String message = '';
  double? monto;

  bool _listening = false;
  bool _busy = false;
  Position? _pos;
  Timer? _resetTimer;
  bool nfcActivo = true;

  Future<void> start() async {
    if (_listening && NfcService.isOwner(this)) return;
    final ok = await NfcService.isNfcAvailable();
    if (ok != nfcActivo) {
      nfcActivo = ok;
      if (!_disposed) notifyListeners();
    }
    if (!ok) return; // sin NFC no hay sesión; se reintenta al volver de Ajustes
    _listening = true;
    unawaited(_cachearUbicacion());
    await NfcService.startSession(
      owner: this,
      onSuccess: _onTag,
      onError: (e) {
        if (!_busy) _mostrar(NfcUiState.error, msg: e);
      },
    );
  }

  Future<void> restart() async {
    if (_busy) return; // no cortar un pago en curso
    await stop();
    await start();
  }

  Future<void> stop() async {
    _listening = false;
    _resetTimer?.cancel();
    _busy = false;
    state = NfcUiState.idle;
    await NfcService.stopSession(owner: this);
  }

  Future<void> _cachearUbicacion() async {
    try {
      _pos = await determinePosition();
    } catch (_) {}
  }

  Future<void> _onTag(Map<String, dynamic> dataNfc) async {
    if (_busy) {
      return; // anti doble cobro: ignora lecturas mientras procesa y durante el enfriamiento
    }
    final card = tarjeta;
    if (card == null) {
      _mostrar(NfcUiState.error, msg: 'Selecciona una tarjeta para pagar');
      return;
    }
    _busy = true;
    _mostrar(NfcUiState.processing);

    final r = await _payments.procesarPagoNfc(
      dataNfc: dataNfc,
      tarjetaSeleccionada: card,
      idCliente: idCliente,
      latitud: _pos?.latitude,
      longitud: _pos?.longitude,
    );
    PasajeEmergenciaState.instance.aplicar(r);
    final tarifa = (dataNfc['tarifa'] ?? 3207).toDouble();
    switch (r.status) {
      case PagoNfcStatus.success:
        HapticFeedback.mediumImpact();
        _mostrar(NfcUiState.success, m: r.montoCobrado ?? tarifa);
        unawaited(_postPago(dataNfc));
      case PagoNfcStatus.ecoPassSuccess:
        // Viaje gratis con pasaje Eco: no se cobra y NO suma punto
        // (así no se encadenan pasajes gratis).
        HapticFeedback.mediumImpact();
        _mostrar(NfcUiState.ecoPass, m: 0);
        unawaited(_postPago(dataNfc, sumarPunto: false));
      case PagoNfcStatus.emergencySuccess:
        HapticFeedback.mediumImpact();
        _mostrar(NfcUiState.emergency, m: tarifa);
        unawaited(_postPago(dataNfc));
      case PagoNfcStatus.successWithEmergency:
        HapticFeedback.mediumImpact();
        _mostrar(NfcUiState.successWithDebt, m: r.montoCobrado);
        unawaited(_postPago(dataNfc));
      case PagoNfcStatus.rejected:
        HapticFeedback.heavyImpact();
        _mostrar(NfcUiState.rejected, msg: r.message);
      case PagoNfcStatus.error:
        _mostrar(NfcUiState.error, msg: r.message);
    }
  }

  Future<void> _postPago(
    Map<String, dynamic> dataNfc, {
    bool sumarPunto = true,
  }) async {
    try {
      if (sumarPunto) {
        final res = await _puntos.sumarPuntoPorViaje();
        if (res?.pasajeGanado == true && !_disposed) {
          onPasajeEcoGanado?.call();
        }
      } else {
        // Se gastó un pasaje Eco: refresca el contador del top bar.
        await _puntos.obtenerEstado();
      }
    } catch (_) {}
    try {
      await _rutas.create(
        RutaFavorita(
          idUsuario: idCliente,
          idRuta: int.tryParse('${dataNfc['id_ruta']}'),
        ),
      );
    } catch (_) {}
  }

  void _mostrar(NfcUiState s, {String msg = '', double? m}) {
    state = s;
    message = msg;
    monto = m;
    notifyListeners();
    _resetTimer?.cancel();
    if (s != NfcUiState.processing) {
      _resetTimer = Timer(const Duration(seconds: 3), () {
        state = NfcUiState.idle;
        _busy = false;
        notifyListeners();
        if (s == NfcUiState.success ||
            s == NfcUiState.ecoPass ||
            s == NfcUiState.emergency ||
            s == NfcUiState.successWithDebt) {
          onPagoCompletado?.call();
        }
      });
    }
  }
}
