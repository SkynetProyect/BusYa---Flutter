import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/Home.dart';
import 'package:flutter_application_1/service/notification_service.dart'
    show NotificationService;
import 'package:intl/date_symbol_data_local.dart';
import 'app_keys.dart';
import 'core/route_observer.dart';
import 'core/supabase_client.dart';
import 'core/auth_listener.dart';
import 'page/auth/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/service/dispositivo_fcm_service.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await themeController.loadTheme();

  // Inicializar Firebase una sola vez.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM en segundo plano.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Fechas en español.
  await initializeDateFormatting('es_CO');

  // Supabase.
  await SupabaseConfig.init();

  debugPrint(
    '[AUTH DEBUG] Supabase initialized. '
    'currentUser=${supabase.auth.currentUser?.id}, '
    'hasSession=${supabase.auth.currentSession != null}',
  );

  AuthListener.listenAuthChanges();

  // Token FCM.
  DispositivoFcmService.instance.init();

  // Notificaciones locales.
  await NotificationService().init();

  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [
            routeObserver,
          ], // <- nuevo: NFC sabe cuándo lo tapan
          title: 'BusYa',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          home: session == null ? const LoginPage() : const Application(),
        );
      },
    );
  }
}
