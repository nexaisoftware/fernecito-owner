import 'package:flutter/material.dart';

import 'core/owner_theme.dart';
import 'screens/auth_gate.dart';

final GlobalKey<ScaffoldMessengerState> ownerScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fernecito Owner',
      debugShowCheckedModeBanner: false,
      theme: OwnerTheme.light(),
      scaffoldMessengerKey: ownerScaffoldMessengerKey,
      home: const AuthGate(),
    );
  }
}
