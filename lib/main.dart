import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/Home.dart';
import 'app_keys.dart';
import 'core/supabase_client.dart';
import 'core/auth_listener.dart';
import 'page/auth/login_page.dart';

Future<void> main() async {
  // para operaciones asincrónicas antes de ejecutar la aplicación
  WidgetsFlutterBinding.ensureInitialized();
  //se inicia supabase
  await SupabaseConfig.init();
  AuthListener.listenAuthChanges();
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Busya",
      home: session != null ? const Application() : const LoginPage(),
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
