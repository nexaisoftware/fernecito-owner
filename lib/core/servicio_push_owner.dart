library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config_push_web.dart';
import 'push_web_helper.dart';

class ServicioPushOwner {
  ServicioPushOwner._();
  static final ServicioPushOwner instancia = ServicioPushOwner._();

  static const String _app = 'owner';

  bool _inicializado = false;
  String? _ultimoTokenRegistrado;

  bool get soportado => kIsWeb && ConfigPushWeb.habilitada;

  Future<void> inicializar() async {
    if (_inicializado || !soportado) return;
    _inicializado = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _registrarToken(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      debugPrint('📩 Push owner en primer plano: ${msg.notification?.title}');
      unawaited(
        mostrarNotificacionForegroundWeb(
          titulo: msg.notification?.title ?? 'Fernecito Owner',
          cuerpo: msg.notification?.body ?? '',
        ),
      );
    });
  }

  Future<bool> registrarParaOwner() async {
    if (!soportado) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 Permiso push owner: ${settings.authorizationStatus.name}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      await asegurarServiceWorkerPush();
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: ConfigPushWeb.vapidKey,
      );
      if (token != null && token.isNotEmpty) {
        await _registrarToken(token);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ registrarParaOwner push: $e');
    }
    return false;
  }

  Future<void> sincronizarSiAutorizado() async {
    if (!soportado) return;
    if (!await tienePermiso()) return;
    await asegurarServiceWorkerPush();
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: ConfigPushWeb.vapidKey,
    );
    if (token != null && token.isNotEmpty) {
      await _registrarToken(token);
    }
  }

  Future<bool> tienePermiso() async {
    if (!soportado) return false;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registrarToken(String token) async {
    if (token == _ultimoTokenRegistrado) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'registrar_push_token',
        body: {
          'token': token,
          'app': _app,
          'plataforma': 'web',
        },
      );
      _ultimoTokenRegistrado = token;
      debugPrint('✅ Token push owner registrado');
    } catch (e) {
      debugPrint('⚠️ registrar token push owner: $e');
    }
  }

  void olvidarLocal() {
    _ultimoTokenRegistrado = null;
  }
}
