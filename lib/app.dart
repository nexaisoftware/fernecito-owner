import 'package:flutter/material.dart';

import 'core/owner_theme.dart';
import 'screens/auth_gate.dart';
import 'widgets/control_actualizacion_web.dart';
import 'widgets/control_instalar_pwa.dart';

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
      builder: (context, child) => ControlInstalarPwa(
        child: ControlActualizacionWeb(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
