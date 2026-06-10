import 'package:supabase_flutter/supabase_flutter.dart';

/// Ticket de soporte de un local (1 row por local en `locales_soporte`).
class SoporteTicket {
  final String idLocal;
  final String codigoAntiestafa;
  final String estado; // 'abierta' | 'terminada'
  final String? viaContacto; // 'email' | 'whatsapp' | null
  final DateTime? ultimaOperacion;
  final String? localUsername;
  final String? nombreLocal;
  final String? fotoPerfilUrl;
  final String? planSuscripcion;
  final bool localVerificado;

  SoporteTicket({
    required this.idLocal,
    required this.codigoAntiestafa,
    required this.estado,
    required this.viaContacto,
    required this.ultimaOperacion,
    required this.localUsername,
    required this.nombreLocal,
    required this.fotoPerfilUrl,
    required this.planSuscripcion,
    required this.localVerificado,
  });

  bool get esAbierta => estado == 'abierta';

  factory SoporteTicket.fromJson(Map<String, dynamic> j) {
    return SoporteTicket(
      idLocal: j['id_local']?.toString() ?? '',
      codigoAntiestafa: j['codigo_antiestafa']?.toString() ?? '',
      estado: j['estado_operacion']?.toString() ?? 'abierta',
      viaContacto: j['via_contacto']?.toString(),
      ultimaOperacion: j['ultima_operacion'] != null
          ? DateTime.tryParse(j['ultima_operacion'].toString())
          : null,
      localUsername: j['local_username']?.toString(),
      nombreLocal: j['nombre_local']?.toString(),
      fotoPerfilUrl: j['foto_perfil_url']?.toString(),
      planSuscripcion: j['plan_suscripcion']?.toString(),
      localVerificado: j['local_verificado'] == true,
    );
  }
}

class OwnerSoporteService {
  OwnerSoporteService._();
  static final OwnerSoporteService instance = OwnerSoporteService._();

  SupabaseClient get _sb => Supabase.instance.client;

  /// Lista tickets. Si [soloAbiertos]=true, filtra a estado='abierta'.
  Future<List<SoporteTicket>> listar({bool soloAbiertos = false}) async {
    final res = await _sb.rpc('soporte_listar', params: {
      'p_solo_abiertos': soloAbiertos,
    });
    if (res is Map && res['tickets'] is List) {
      return (res['tickets'] as List)
          .whereType<Map>()
          .map((m) => SoporteTicket.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// Marca el ticket como 'terminada'.
  Future<Map<String, dynamic>> cerrar(String idLocal) async {
    final res = await _sb.rpc('soporte_cerrar', params: {
      'p_id_local': idLocal,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false};
  }
}
