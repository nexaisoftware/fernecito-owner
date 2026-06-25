import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

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
