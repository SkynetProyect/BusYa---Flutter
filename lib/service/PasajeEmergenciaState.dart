import 'package:flutter/foundation.dart';
import '../model/PagoNfcResult.dart';
import 'rest/transaccion_nfc/TransaccionNfcService.dart';

class PasajeEmergenciaState extends ChangeNotifier {
  PasajeEmergenciaState._();
  static final instance = PasajeEmergenciaState._();

  double? _monto;
  bool _cargado = false;
  double? get monto => _monto;
  bool get debe => _monto != null;

  /// Única consulta a BD: al entrar a Pagos la primera vez.
  Future<void> cargar(String idCliente) async {
    if (_cargado) return;
    final resp = await TransaccionNfcService().getEmergenciaPendiente(
      idCliente,
    );
    _monto = (resp?['monto'] as num?)?.toDouble();
    _cargado = true;
    notifyListeners();
  }

  /// Después de cada pago manda la respuesta del micro.
  void aplicar(PagoNfcResult r) {
    if (r.status == PagoNfcStatus.error || r.tieneDeudaPendiente == null)
      return;
    _monto = r.tieneDeudaPendiente! ? r.montoPendiente : null;
    notifyListeners();
  }

  void reset() {
    _monto = null;
    _cargado = false;
    notifyListeners();
  } // llamar al cerrar sesión
}
