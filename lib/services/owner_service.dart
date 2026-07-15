import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cron_owner_tipo.dart';
import '../models/push_filtros.dart';

class OwnerService {
  OwnerService._();
  static final OwnerService instance = OwnerService._();

  SupabaseClient get _sb => Supabase.instance.client;

  User? get currentUser => _sb.auth.currentUser;

  Stream<AuthState> get authStream => _sb.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await _sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  /// Llama RPC vincular_owner_si_corresponde y luego es_owner_activo.
  /// Devuelve true si el usuario es owner activo.
  Future<bool> verificarOwner() async {
    final user = currentUser;
    if (user == null) return false;
    final email = (user.email ?? '').toLowerCase();
    if (email.isEmpty) return false;

    try {
      await _sb.rpc(
        'vincular_owner_si_corresponde',
        params: {'p_email': email},
      );
    } catch (_) {
      // no crítico
    }

    final res = await _sb.rpc('es_owner_activo', params: {'p_uid': user.id});
    return res == true;
  }

  /// Lista de pagos según filtro de estado.
  /// estados: 'pendiente' | 'aplicado' | 'aprobado_pendiente' | 'rechazado'
  Future<List<Map<String, dynamic>>> listarPagos({
    List<String> estados = const ['pendiente'],
    int limit = 100,
  }) async {
    final query = _sb
        .from('pagos_pendientes')
        .select(
          'id, perfil_id, local_username, plan_solicitado, plan_anterior, '
          'tipo_solicitud, monto_usd, monto_ars, cotizacion_blue, comprobante_url, '
          'estado, notas, aprobado_por, aplica_desde, creado_en, revisado_en',
        )
        .inFilter('estado', estados)
        .order('creado_en', ascending: false)
        .limit(limit);
    final data = await query;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Obtiene URL firmada del comprobante (bucket privado).
  Future<String?> urlComprobante(String path) async {
    try {
      final res = await _sb.storage
          .from('comprobantes_pagos')
          .createSignedUrl(path, 60 * 60); // 1h
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> aprobarPago(String pagoId, {String? notas}) async {
    final res = await _sb.functions.invoke(
      'aprobar_pago_local',
      body: {'pago_id': pagoId, 'accion': 'aprobar', 'notas': ?notas},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> rechazarPago(String pagoId, {required String motivo}) async {
    final res = await _sb.functions.invoke(
      'aprobar_pago_local',
      body: {'pago_id': pagoId, 'accion': 'rechazar', 'notas': motivo},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Ejecuta cron de planes (legacy — preferir [ejecutarCronOwner]).
  Future<Map<String, dynamic>> ejecutarCronManual() async {
    return ejecutarCronOwner(tipo: CronOwnerTipo.suscripciones);
  }

  /// Fuerza crons del sistema. Solo owner.
  /// [tipo]: todos | suscripciones | notificaciones | eventos | pioneros
  Future<Map<String, dynamic>> ejecutarCronOwner({
    required CronOwnerTipo tipo,
  }) async {
    final res = await _sb.functions.invoke(
      'ejecutar_cron_owner',
      body: {'tipo': tipo.id},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Envía una notificación push masiva. Solo owner.
  Future<Map<String, dynamic>> enviarPushMasiva({
    required String titulo,
    required String cuerpo,
    required String target,
    PushFiltros? filtros,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'cuerpo': cuerpo,
      'target': target,
    };
    if (filtros != null && filtros.activo) {
      body['filtros'] = filtros.toJson();
    }
    final res = await _sb.functions.invoke('enviar_push_masiva', body: body);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Cuenta dispositivos alcanzables según target y filtros (solo owner).
  Future<int> contarAlcancePush({
    required String target,
    PushFiltros? filtros,
  }) async {
    final params = <String, dynamic>{'p_target': target};
    if (filtros != null && filtros.activo) {
      params['p_filtros'] = filtros.toJson();
    }
    final res = await _sb.rpc('owner_push_alcance', params: params);
    return (res as num?)?.toInt() ?? 0;
  }

  /// Historial de envíos de push (para el panel Notificar).
  Future<List<Map<String, dynamic>>> listarEnviosPush({int limit = 20}) async {
    final data = await _sb
        .from('push_envios')
        .select('titulo, cuerpo, segmento, destinatarios, exitosos, fallidos, fecha')
        .order('fecha', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }
}
