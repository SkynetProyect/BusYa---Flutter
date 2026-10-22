import 'package:flutter/material.dart';

/// Observador global de rutas. Permite que un widget con RouteAware
/// sepa cuándo otra pantalla se abre encima o se cierra.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
