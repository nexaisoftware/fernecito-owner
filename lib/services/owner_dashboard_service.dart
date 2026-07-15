import 'owner_admin_service.dart';
import 'owner_metrics_service.dart';
import 'owner_service.dart';
import 'owner_soporte_service.dart';

/// Resumen ligero para el dashboard (alertas + panorama + cards informativas).
class OwnerDashboardResumen {
  final int pagosPendientes;
  final int pagosAgendados;
  final int soporteLocalesAbiertos;
  final int soporteUsuariosAbiertos;
  final int reportesModeracion;
  final int reportesUrgentes;
  final int usuarios;
  final int locales;
  final int eventosActivos;
  final int localesPagos;
  final double ingresosUsd;
  final double ingresosArs;
  final List<String> erroresParciales;

  const OwnerDashboardResumen({
    required this.pagosPendientes,
    required this.pagosAgendados,
    required this.soporteLocalesAbiertos,
    required this.soporteUsuariosAbiertos,
    required this.reportesModeracion,
    required this.reportesUrgentes,
    required this.usuarios,
    required this.locales,
    required this.eventosActivos,
    required this.localesPagos,
    required this.ingresosUsd,
    required this.ingresosArs,
    this.erroresParciales = const [],
  });

  int get soporteAbiertosTotal =>
      soporteLocalesAbiertos + soporteUsuariosAbiertos;

  bool get tieneErroresParciales => erroresParciales.isNotEmpty;

  static const vacio = OwnerDashboardResumen(
    pagosPendientes: 0,
    pagosAgendados: 0,
    soporteLocalesAbiertos: 0,
    soporteUsuariosAbiertos: 0,
    reportesModeracion: 0,
    reportesUrgentes: 0,
    usuarios: 0,
    locales: 0,
    eventosActivos: 0,
    localesPagos: 0,
    ingresosUsd: 0,
    ingresosArs: 0,
  );
}

class OwnerDashboardService {
  OwnerDashboardService._();
  static final OwnerDashboardService instance = OwnerDashboardService._();

  Future<OwnerDashboardResumen> cargar() async {
    final errores = <String>[];
    var pagosPendientes = 0;
    var pagosAgendados = 0;
    var soporteLocales = 0;
    var soporteUsuarios = 0;
    var reportesTotal = 0;
    var reportesUrgentes = 0;
    var metricas = OwnerMetricsSnapshot.vacio();

    try {
      pagosPendientes = (await OwnerService.instance.listarPagos(
        estados: const ['pendiente'],
        limit: 200,
      )).length;
    } catch (e) {
      errores.add('Pagos pendientes');
    }

    try {
      pagosAgendados = (await OwnerService.instance.listarPagos(
        estados: const ['aprobado_pendiente'],
        limit: 200,
      )).length;
    } catch (e) {
      errores.add('Pagos agendados');
    }

    try {
      soporteLocales =
          (await OwnerSoporteService.instance.listar(soloAbiertos: true)).length;
    } catch (e) {
      errores.add('Soporte locales');
    }

    try {
      soporteUsuarios = (await OwnerSoporteService.instance.listarUsuarios(
        soloAbiertos: true,
      )).length;
    } catch (e) {
      errores.add('Soporte usuarios');
    }

    try {
      final reportes = await OwnerAdminService.instance.listarReportes();
      reportesTotal = reportes.length;
      for (final r in reportes) {
        final count = (r['cantidad_reportes'] as num?)?.toInt() ?? 0;
        if (count > 4) reportesUrgentes++;
      }
    } catch (e) {
      errores.add('Moderación');
    }

    try {
      metricas = await OwnerMetricsService.instance.cargar();
    } catch (e) {
      errores.add('Métricas');
    }

    return OwnerDashboardResumen(
      pagosPendientes: pagosPendientes,
      pagosAgendados: pagosAgendados,
      soporteLocalesAbiertos: soporteLocales,
      soporteUsuariosAbiertos: soporteUsuarios,
      reportesModeracion: reportesTotal,
      reportesUrgentes: reportesUrgentes,
      usuarios: metricas.usuarios,
      locales: metricas.locales,
      eventosActivos: metricas.eventosActivos,
      localesPagos: metricas.localesPagos,
      ingresosUsd: metricas.ingresosUsd,
      ingresosArs: metricas.ingresosArs,
      erroresParciales: errores,
    );
  }
}
