import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/route_observer.dart';
import 'package:flutter_application_1/service/NfcPaymentController.dart';

/// Enciende el NFC solo mientras esta pantalla es la visible:
/// - se apaga si otra pantalla, diálogo o bottom sheet se abre encima
/// - se apaga si la app pasa a segundo plano
/// - se apaga al destruirse la pantalla
class NfcListenScope extends StatefulWidget {
  const NfcListenScope({
    super.key,
    required this.controller,
    required this.child,
    this.active = true,
  });

  final NfcPaymentController controller;
  final bool active; // true por defecto; solo lo usarías con IndexedStack
  final Widget child;

  @override
  State<NfcListenScope> createState() => _NfcListenScopeState();
}

class _NfcListenScopeState extends State<NfcListenScope>
    with WidgetsBindingObserver, RouteAware {
  bool _covered = false; // true si hay otra pantalla encima
  ModalRoute<void>? _route;

  bool get _shouldListen => widget.active && !_covered;

  void _sync() =>
      _shouldListen ? widget.controller.start() : widget.controller.stop();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_shouldListen) widget.controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _covered = true;
    _sync();
  }

  @override
  void didPopNext() {
    _covered = false;
    _sync();
  }

  @override
  void didUpdateWidget(NfcListenScope old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && _shouldListen) {
      widget.controller.restart(); // también re-revisa si ya activó el NFC
    }
    if (s == AppLifecycleState.paused) widget.controller.stop();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
