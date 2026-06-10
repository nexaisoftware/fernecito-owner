import 'package:supabase_flutter/supabase_flutter.dart';

/// Snapshot completo de métricas del dashboard owner.
/// Viene de la RPC `metricas_owner_completas` (un solo round-trip).
class OwnerMetricsSnapshot {
  // Cuentas
  final int cuentasTotal;
  final int usuarios;
  final int locales;

  // Planes (sin_verificar = cuentas locales no verificadas; gratis = verificado en plan gratis)
  final int planSinVerificar;
  final int planGratis;
  final int planStandard;
  final int planPlus;
  final int planPremium;
  final int planPionero;
  final int localesPagos;

  // Verificación
  final int verificados;
  final int noVerificados;

  // Eventos
  final int eventosTotal;
  final int eventosPublicados;
  final int eventosActivos;
  final int jerarqUltra;
  final int jerarqTop;
  final int jerarqReco;
  final int jerarqGratis;
  final int jerarqNormal;
  final int eventosVisitas;
  final int eventosReservas;
  final int tokensEmitidos;
  final int tokensCanjeados;

  // Flyers IA
  final int flyersTotal;
  final int flyersEntregados;
  final int flyersCreditos;
  final int flyersEsteMes;
  final int flyersRetries;
  final double flyersTasaEntrega;

  // Promos
  final int promosTotal;
  final int promosActivas;
  final int promosCuposUsados;

  // Reviews
  final int reviewsTotal;
  final double reviewsPromedio;

  // Pagos
  final int pagosPendientes;
  final int pagosAplicados;
  final int pagosRechazados;
  final double ingresosUsd;
  final double ingresosArs;

  final DateTime? generadoEn;

  const OwnerMetricsSnapshot({
    required this.cuentasTotal,
    required this.usuarios,
    required this.locales,
    required this.planSinVerificar,
    required this.planGratis,
    required this.planStandard,
    required this.planPlus,
    required this.planPremium,
    required this.planPionero,
    required this.localesPagos,
    required this.verificados,
    required this.noVerificados,
    required this.eventosTotal,
    required this.eventosPublicados,
    required this.eventosActivos,
    required this.jerarqUltra,
    required this.jerarqTop,
    required this.jerarqReco,
    required this.jerarqGratis,
    required this.jerarqNormal,
    required this.eventosVisitas,
    required this.eventosReservas,
    required this.tokensEmitidos,
    required this.tokensCanjeados,
    required this.flyersTotal,
    required this.flyersEntregados,
    required this.flyersCreditos,
    required this.flyersEsteMes,
    required this.flyersRetries,
    required this.flyersTasaEntrega,
    required this.promosTotal,
    required this.promosActivas,
    required this.promosCuposUsados,
    required this.reviewsTotal,
    required this.reviewsPromedio,
    required this.pagosPendientes,
    required this.pagosAplicados,
    required this.pagosRechazados,
    required this.ingresosUsd,
    required this.ingresosArs,
    this.generadoEn,
  });

  factory OwnerMetricsSnapshot.vacio() => const OwnerMetricsSnapshot(
        cuentasTotal: 0, usuarios: 0, locales: 0,
        planSinVerificar: 0, planGratis: 0, planStandard: 0, planPlus: 0, planPremium: 0, planPionero: 0,
        localesPagos: 0, verificados: 0, noVerificados: 0,
        eventosTotal: 0, eventosPublicados: 0, eventosActivos: 0,
        jerarqUltra: 0, jerarqTop: 0, jerarqReco: 0, jerarqGratis: 0, jerarqNormal: 0,
        eventosVisitas: 0, eventosReservas: 0, tokensEmitidos: 0, tokensCanjeados: 0,
        flyersTotal: 0, flyersEntregados: 0, flyersCreditos: 0,
        flyersEsteMes: 0, flyersRetries: 0, flyersTasaEntrega: 0,
        promosTotal: 0, promosActivas: 0, promosCuposUsados: 0,
        reviewsTotal: 0, reviewsPromedio: 0,
        pagosPendientes: 0, pagosAplicados: 0, pagosRechazados: 0,
        ingresosUsd: 0, ingresosArs: 0,
      );

  factory OwnerMetricsSnapshot.fromJson(Map<String, dynamic> j) {
    int i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    double d(dynamic v) => v is double ? v : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    Map<String, dynamic> m(dynamic v) =>
        v is Map<String, dynamic> ? v : (v is Map ? Map<String, dynamic>.from(v) : {});
    final cuentas = m(j['cuentas']);
    final ver = m(j['verificacion']);
    final planes = m(j['planes']);
    final ev = m(j['eventos']);
    final jer = m(ev['jerarquias']);
    final fl = m(j['flyers_ia']);
    final pro = m(j['promociones']);
    final rev = m(j['reviews']);
    final pa = m(j['pagos']);
    return OwnerMetricsSnapshot(
      cuentasTotal: i(cuentas['total']),
      usuarios: i(cuentas['usuarios']),
      locales: i(cuentas['locales']),
      planSinVerificar: planes.containsKey('sin_verificar')
          ? i(planes['sin_verificar'])
          : i(ver['no_verificados']),
      planGratis: i(planes['gratis']),
      planStandard: i(planes['standard']),
      planPlus: i(planes['plus']),
      planPremium: i(planes['premium']),
      planPionero: i(planes['pionero']),
      localesPagos: i(planes['pagos']),
      verificados: i(ver['verificados']),
      noVerificados: i(ver['no_verificados']),
      eventosTotal: i(ev['total']),
      eventosPublicados: i(ev['publicados']),
      eventosActivos: i(ev['activos']),
      jerarqUltra: i(jer['top_ultra']),
      jerarqTop: i(jer['top']),
      jerarqReco: i(jer['recomendado']),
      jerarqGratis: i(jer['gratis']),
      jerarqNormal: i(jer['normal']),
      eventosVisitas: i(ev['visitas']),
      eventosReservas: i(ev['reservas']),
      tokensEmitidos: i(ev['tokens_emitidos']),
      tokensCanjeados: i(ev['tokens_canjeados']),
      flyersTotal: i(fl['total']),
      flyersEntregados: i(fl['entregados']),
      flyersCreditos: i(fl['creditos_usados']),
      flyersEsteMes: i(fl['este_mes']),
      flyersRetries: i(fl['retries']),
      flyersTasaEntrega: d(fl['tasa_entrega_pct']),
      promosTotal: i(pro['total']),
      promosActivas: i(pro['activas']),
      promosCuposUsados: i(pro['cupos_usados']),
      reviewsTotal: i(rev['total']),
      reviewsPromedio: d(rev['promedio_estrellas']),
      pagosPendientes: i(pa['pendientes']),
      pagosAplicados: i(pa['aplicados']),
      pagosRechazados: i(pa['rechazados']),
      ingresosUsd: d(pa['ingresos_usd_total']),
      ingresosArs: d(pa['ingresos_ars_total']),
      generadoEn: j['generado_en'] != null
          ? DateTime.tryParse(j['generado_en'].toString())
          : null,
    );
  }
}

class OwnerMetricsService {
  OwnerMetricsService._();
  static final OwnerMetricsService instance = OwnerMetricsService._();

  SupabaseClient get _sb => Supabase.instance.client;

  Future<OwnerMetricsSnapshot> cargar() async {
    final data = await _sb.rpc('metricas_owner_completas');
    if (data is Map) {
      return OwnerMetricsSnapshot.fromJson(Map<String, dynamic>.from(data));
    }
    return OwnerMetricsSnapshot.vacio();
  }
}
