import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['URL_SUPABASE'] ?? '',
    anonKey: dotenv.env['CLAVE_PUBLICA_SUPABASE'] ?? '',
  );
  runApp(const OwnerApp());
}
