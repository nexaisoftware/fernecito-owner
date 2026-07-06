import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerAdminService {
  OwnerAdminService._();
  static final OwnerAdminService instance = OwnerAdminService._();

  SupabaseClient get _sb => Supabase.instance.client;

  /// Búsqueda fuzzy de usuarios por username o nombre.
  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) async {
    final res = await _sb.rpc(
      'admin_buscar_usuarios',
      params: {'p_query': query},
    );
    if (res is Map && res['results'] is List) {
      return (res['results'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> buscarLocales(String query) async {
    final res = await _sb.rpc(
      'admin_buscar_locales',
      params: {'p_query': query},
    );
    if (res is Map && res['results'] is List) {
      return (res['results'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> listarReportes() async {
    final res = await _sb.rpc('owner_listar_reportes_cuentas');
    if (res is Map && res['results'] is List) {
      return (res['results'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> eliminarReportesCuenta({
    required String targetTipo,
    required String targetId,
  }) async {
    try {
      final res = await _sb.rpc(
        'owner_eliminar_reportes_cuenta',
        params: {'p_target_tipo': targetTipo, 'p_target_id': targetId},
      );
      return _mapRpc(res);
    } on PostgrestException catch (e) {
      return _rpcError(e);
    } catch (e) {
      return {'ok': false, 'code': 'network_error', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> detalleUsuario(String id) async {
    final res = await _sb.rpc(
      'admin_get_usuario_detalle',
      params: {'p_id': id},
    );
    if (res is Map && res['ok'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> detalleLocal(String id) async {
    final res = await _sb.rpc('admin_get_local_detalle', params: {'p_id': id});
    if (res is Map && res['ok'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>> generarCodigoPionero(String idLocal) async {
    try {
      final res = await _sb.rpc(
        'owner_generar_codigo_pionero',
        params: {'p_id_local': idLocal},
      );
      return _mapRpc(res);
    } on PostgrestException catch (e) {
      return _rpcError(e);
    } catch (e) {
      return {'ok': false, 'code': 'network_error', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> quitarPionero(String idLocal) async {
    try {
      final res = await _sb.rpc(
        'owner_quitar_pionero',
        params: {'p_id_local': idLocal},
      );
      return _mapRpc(res);
    } on PostgrestException catch (e) {
      return _rpcError(e);
    } catch (e) {
      return {'ok': false, 'code': 'network_error', 'error': e.toString()};
    }
  }

  /// Pausa o reactiva una cuenta.
  /// [tipo]: 'usuario' | 'local'
  /// [pausar]: true=pausar, false=reactivar
  Future<Map<String, dynamic>> pausarCuenta({
    required String targetId,
    required String tipo,
    required bool pausar,
    String? motivo,
    String? motivoPublico,
  }) async {
    final baseParams = <String, dynamic>{
      'p_target_id': targetId,
      'p_target_type': tipo,
      'p_pausar': pausar,
      'p_motivo': motivo,
    };

    try {
      final res = await _sb.rpc(
        'admin_pausar_cuenta',
        params: {
          ...baseParams,
          if (motivoPublico != null && motivoPublico.isNotEmpty)
            'p_motivo_publico': motivoPublico,
        },
      );
      return _mapRpc(res);
    } on PostgrestException catch (e) {
      // Compat: prod sin migración 20260529300000 (RPC de 4 params, sin motivo_publico).
      if (_rpcFirmaIncompatible(e) &&
          motivoPublico != null &&
          motivoPublico.isNotEmpty) {
        try {
          final legacy = await _sb.rpc(
            'admin_pausar_cuenta',
            params: baseParams,
          );
          return _mapRpc(legacy);
        } on PostgrestException catch (e2) {
          return _rpcError(e2);
        }
      }
      return _rpcError(e);
    } catch (e) {
      return {'ok': false, 'code': 'network_error', 'error': e.toString()};
    }
  }

  Map<String, dynamic> _mapRpc(dynamic res) {
    if (res is Map) return Map<String, dynamic>.from(res);
    return {
      'ok': false,
      'code': 'invalid_response',
      'error': 'Respuesta inválida del servidor',
    };
  }

  bool _rpcFirmaIncompatible(PostgrestException e) {
    final msg = '${e.message} ${e.details ?? ''}'.toLowerCase();
    return msg.contains('p_motivo_publico') ||
        msg.contains('could not find the function') ||
        msg.contains('does not exist') ||
        msg.contains('pgrst202');
  }

  Map<String, dynamic> _rpcError(PostgrestException e) {
    final msg = e.message;
    final lower = msg.toLowerCase();
    if (lower.contains('no_autorizado') || e.code == '42501') {
      return {
        'ok': false,
        'code': 'no_autorizado',
        'error': 'Tu sesión no tiene permisos de owner activos.',
      };
    }
    if (lower.contains('could not find the function') ||
        lower.contains('pgrst202')) {
      return {
        'ok': false,
        'code': 'rpc_not_found',
        'error': 'Falta aplicar la migración admin_pausar_cuenta en Supabase.',
      };
    }
    return {'ok': false, 'code': e.code ?? 'rpc_error', 'error': msg};
  }

  /// Dispara reset password email para el target.
  Future<Map<String, dynamic>> resetPassword(String targetId) async {
    final res = await _sb.functions.invoke(
      'admin_acciones_usuario',
      body: {'accion': 'reset_password', 'target_id': targetId},
    );
    if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
    return {'ok': false};
  }

  /// Genera una pass temporal aleatoria, la setea en auth.users y la devuelve
  /// para que el owner se la pase al usuario por soporte.
  Future<Map<String, dynamic>> setPasswordTemporal(String targetId) async {
    final res = await _sb.functions.invoke(
      'admin_acciones_usuario',
      body: {'accion': 'set_password_temporal', 'target_id': targetId},
    );
    if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
    return {'ok': false};
  }

  /// Elimina cuenta auth (cascade limpia perfiles).
  Future<Map<String, dynamic>> eliminarCuenta(String targetId) async {
    final res = await _sb.functions.invoke(
      'admin_acciones_usuario',
      body: {'accion': 'eliminar', 'target_id': targetId},
    );
    if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
    return {'ok': false};
  }
}
