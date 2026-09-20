import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/Home.dart' show Application;
import 'package:flutter_application_1/page/auth/login_page.dart' show LoginPage;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_keys.dart';
import 'supabase_client.dart';

class AuthListener {
  static void listenAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const Application()),
              (route) => false,
            );
          }
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          break;
        default:
          break;
      }
    });
  }
}
