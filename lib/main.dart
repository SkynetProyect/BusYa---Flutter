import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/Home.dart';
import 'package:flutter_application_1/service/notification_service.dart'
    show NotificationService;
import 'package:intl/date_symbol_data_local.dart';
import 'app_keys.dart';
import 'core/app_colors.dart';
import 'core/supabase_client.dart';
import 'core/auth_listener.dart';
import 'page/auth/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/service/dispositivo_fcm_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'BusYa',
      home: session == null ? const LoginPage() : const Application(),
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
      ),
    );
  }
}
