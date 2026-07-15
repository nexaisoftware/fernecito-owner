import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config_push_web.dart';
import 'core/servicio_push_owner.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  final url = _config('URL_SUPABASE');
  final clave = _config('CLAVE_PUBLICA_SUPABASE');
  if (url.isEmpty || clave.isEmpty) {
    throw StateError(
      'Faltan URL_SUPABASE o CLAVE_PUBLICA_SUPABASE. '
      'En produccion usá --dart-define; en local podés usar .env.',
    );
  }
  await Supabase.initialize(url: url, anonKey: clave);

  if (kIsWeb && ConfigPushWeb.habilitada) {
    try {
      await Firebase.initializeApp(options: ConfigPushWeb.options);
      FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
      await ServicioPushOwner.instancia.inicializar();
    } catch (e) {
      debugPrint('⚠️ Firebase/push owner no inicializado: $e');
    }
  }

  runApp(const OwnerApp());
}

String _config(String key) {
  const urlSupabase = String.fromEnvironment('URL_SUPABASE');
  const clavePublicaSupabase = String.fromEnvironment('CLAVE_PUBLICA_SUPABASE');

  final fromDefine = switch (key) {
    'URL_SUPABASE' => urlSupabase,
    'CLAVE_PUBLICA_SUPABASE' => clavePublicaSupabase,
    _ => '',
  };
  return fromDefine.isNotEmpty ? fromDefine : (dotenv.env[key] ?? '').trim();
}
