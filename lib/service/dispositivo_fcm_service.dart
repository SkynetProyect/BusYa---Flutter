import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'notification_service.dart';

/// Mantiene el token FCM del dispositivo sincronizado con la tabla
/// dispositivos_fcm (vía funciones RPC de Supabase) y muestra los pushes
/// que llegan con la app abierta.
class DispositivoFcmService {
  DispositivoFcmService._();
  static final DispositivoFcmService instance = DispositivoFcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;

  /// Llamar una sola vez en main(), después de inicializar Supabase.
  void init() {
    if (kIsWeb) return; // FCM web necesita otra configuración

    _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final hayLogin =
          data.session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession);
      if (hayLogin) _registrar();
    });

    // Pushes que llegan con la app en primer plano: Android no los muestra
    // solo, así que se pasan a las notificaciones locales.
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(_mostrarEnPrimerPlano);

    // Si la app arranca con la sesión ya guardada, el evento puede haberse
    // emitido antes de suscribirnos.
    if (supabase.auth.currentSession != null) _registrar();
  }

  Future<void> _mostrarEnPrimerPlano(RemoteMessage message) async {
    final notificacion = message.notification;
    if (notificacion == null) return;

    final local = NotificationService();
    await local.init(); // no hace nada si ya estaba inicializado
    await local.mostrarNotificacion(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      titulo: notificacion.title ?? 'BusYa',
      cuerpo: notificacion.body ?? '',
    );
  }

  /// Llamar ANTES de supabase.auth.signOut(): después ya no hay auth.uid().
  Future<void> eliminarToken() async {
    if (kIsWeb) return;
    try {
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      final token = await _messaging.getToken();
      if (token != null) {
        await supabase.rpc(
          'eliminar_dispositivo_fcm',
          params: {'p_fcm_token': token},
        );
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] No se pudo eliminar el token: $e');
    }
  }

  Future<void> _registrar() async {
    try {
      final permiso = await _messaging.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token == null) return;
      await _guardar(token);

      // El token puede rotar mientras la sesión sigue abierta.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen(_guardar);
    } catch (e) {
      debugPrint('[FCM] No se pudo registrar el token: $e');
    }
  }

  Future<void> _guardar(String token) async {
    await supabase.rpc(
      'registrar_dispositivo_fcm',
      params: {
        'p_fcm_token': token,
        'p_plataforma': defaultTargetPlatform == TargetPlatform.iOS
            ? 'IOS'
            : 'ANDROID',
      },
    );
    debugPrint('[FCM] Token registrado');
  }
}
