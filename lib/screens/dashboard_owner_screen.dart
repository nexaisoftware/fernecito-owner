import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/owner_layout.dart';
import '../core/owner_nav_modulo.dart';
import '../core/owner_theme.dart';
import '../services/owner_dashboard_service.dart';
import '../services/owner_service.dart';
import '../widgets/cron_owner_panel.dart';
import '../widgets/owner_desktop_refresh.dart';
import 'admin_owner_screen.dart';
import 'notificar_owner_screen.dart';
import 'pagos_owner_screen.dart';

/// Hub central: alertas, accesos rápidos y herramientas secundarias.
class DashboardOwnerScreen extends StatefulWidget {
  const DashboardOwnerScreen({
    super.key,
    required this.onIrAModulo,
  });

  final ValueChanged<OwnerNavModulo> onIrAModulo;

  @override
  State<DashboardOwnerScreen> createState() => _DashboardOwnerScreenState();
}

class _DashboardOwnerScreenState extends State<DashboardOwnerScreen> {
  OwnerDashboardResumen _resumen = OwnerDashboardResumen.vacio;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resumen = await OwnerDashboardService.instance.cargar();
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _loading = false;
        _error = resumen.tieneErroresParciales
            ? 'Algunos datos no se pudieron cargar (${resumen.erroresParciales.join(', ')})'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el resumen: $e';
        _loading = false;
      });
    }
  }

  void _abrir(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _cargar());
  }

  @override
  Widget build(BuildContext context) {
    final email = OwnerService.instance.currentUser?.email ?? '';
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 600;
    final columnasHerramientas = ancho >= 900 ? 3 : (ancho >= 520 ? 2 : 1);

    return OwnerDesktopRefreshOverlay(
      onRefresh: _cargar,
      loading: _loading,
      child: RefreshIndicator(
        onRefresh: _cargar,
        color: OwnerTheme.violetaMarca,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _wrapSection(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  compacto ? 20 : 28,
                  0,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio',
                      style: OwnerTheme.baloo(
                        fontSize: compacto ? 24 : 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OwnerTheme.baloo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: OwnerTheme.textoSecundario,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Resumen del panel y accesos rápidos.',
                      style: OwnerTheme.baloo(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: OwnerTheme.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              compacto,
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Text(
                    _error!,
                    style: OwnerTheme.baloo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ),
            ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(child: _wrapSection(_seccionAlertas(compacto), compacto)),
            SliverToBoxAdapter(
              child: _wrapSection(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CronOwnerPanel(onCompletado: _cargar),
                ),
                compacto,
              ),
            ),
            SliverToBoxAdapter(child: _wrapSection(_seccionPanorama(compacto, ancho), compacto)),
            SliverToBoxAdapter(
              child: _wrapSection(
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Text(
                    'Herramientas',
                    style: OwnerTheme.baloo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                compacto,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                compacto ? 16 : 24,
                0,
                compacto ? 16 : 24,
                32,
              ),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: OwnerLayout.contentMaxWidth),
                    child: GridView.count(
                      crossAxisCount: columnasHerramientas,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: columnasHerramientas == 1 ? 2.4 : 1.35,
                      children: [
                  _HerramientaCard(
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF059669),
                    titulo: 'Pagos',
                    subtitulo: 'Aprobar comprobantes y planes',
                    badge: _resumen.pagosPendientes > 0
                        ? '${_resumen.pagosPendientes}'
                        : null,
                    onTap: () => _abrir(const PagosOwnerScreen()),
                  ),
                  _HerramientaCard(
                    icon: Icons.campaign_rounded,
                    color: OwnerTheme.violetaMarca,
                    titulo: 'Notificar',
                    subtitulo: 'Push masiva a usuarios',
                    onTap: () => _abrir(const NotificarOwnerScreen()),
                  ),
                  _HerramientaCard(
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFF2563EB),
                    titulo: 'Administrar',
                    subtitulo: 'Buscar y gestionar cuentas',
                    onTap: () => _abrir(const AdminOwnerScreen()),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _wrapSection(Widget child, bool compacto) {
    return OwnerLayout.constrain(
      context: context,
      padding: EdgeInsets.symmetric(horizontal: compacto ? 16 : 24),
      child: child,
    );
  }

  Widget _seccionPanorama(bool compacto, double ancho) {
    final columnas = ancho >= 900 ? 4 : (ancho >= 520 ? 2 : 2);
    final fmtUsd = NumberFormat.currency(symbol: r'US$', decimalDigits: 0);
    final fmtArs = NumberFormat.currency(symbol: r'$', decimalDigits: 0, locale: 'es_AR');

    return Padding(
      padding: EdgeInsets.only(top: compacto ? 0 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panorama',
            style: OwnerTheme.baloo(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: columnas,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columnas >= 4 ? 1.55 : 1.45,
            children: [
              _StatCard(
                icon: Icons.people_rounded,
                color: const Color(0xFF2563EB),
                valor: '${_resumen.usuarios}',
                etiqueta: 'Usuarios',
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
              _StatCard(
                icon: Icons.storefront_rounded,
                color: OwnerTheme.violetaMarca,
                valor: '${_resumen.locales}',
                etiqueta: 'Locales',
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
              _StatCard(
                icon: Icons.event_available_rounded,
                color: const Color(0xFF059669),
                valor: '${_resumen.eventosActivos}',
                etiqueta: 'Eventos activos',
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
              _StatCard(
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFFD97706),
                valor: '${_resumen.localesPagos}',
                etiqueta: 'Locales de pago',
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
              _StatCard(
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF0EA5E9),
                valor: fmtUsd.format(_resumen.ingresosUsd),
                etiqueta: 'Ingresos USD',
                compacto: true,
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
              _StatCard(
                icon: Icons.payments_rounded,
                color: const Color(0xFF7C3AED),
                valor: fmtArs.format(_resumen.ingresosArs),
                etiqueta: 'Ingresos ARS',
                compacto: true,
                onTap: () => widget.onIrAModulo(OwnerNavModulo.metricas),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionAlertas(bool compacto) {
    final alertas = <Widget>[];

    if (_resumen.pagosPendientes > 0) {
      alertas.add(
        _AlertaCard(
          icon: Icons.payments_rounded,
          color: const Color(0xFF059669),
          titulo: '${_resumen.pagosPendientes} pago${_resumen.pagosPendientes == 1 ? '' : 's'} pendiente${_resumen.pagosPendientes == 1 ? '' : 's'}',
          subtitulo: 'Comprobantes esperando revisión',
          urgente: _resumen.pagosPendientes >= 5,
          onTap: () => _abrir(const PagosOwnerScreen()),
        ),
      );
    }

    if (_resumen.pagosAgendados > 0) {
      alertas.add(
        _AlertaCard(
          icon: Icons.schedule_rounded,
          color: const Color(0xFF0EA5E9),
          titulo: '${_resumen.pagosAgendados} renovación${_resumen.pagosAgendados == 1 ? '' : 'es'} agendada${_resumen.pagosAgendados == 1 ? '' : 's'}',
          subtitulo: 'Planes aprobados pendientes de aplicar',
          onTap: () => _abrir(const PagosOwnerScreen()),
        ),
      );
    }

    if (_resumen.soporteAbiertosTotal > 0) {
      alertas.add(
        _AlertaCard(
          icon: Icons.support_agent_rounded,
          color: const Color(0xFF7C3AED),
          titulo:
              '${_resumen.soporteAbiertosTotal} consulta${_resumen.soporteAbiertosTotal == 1 ? '' : 's'} de soporte sin resolver',
          subtitulo:
              '${_resumen.soporteLocalesAbiertos} locales · ${_resumen.soporteUsuariosAbiertos} usuarios',
          urgente: _resumen.soporteAbiertosTotal >= 3,
          onTap: () => widget.onIrAModulo(OwnerNavModulo.soporte),
        ),
      );
    }

    if (_resumen.reportesModeracion > 0) {
      alertas.add(
        _AlertaCard(
          icon: Icons.report_problem_rounded,
          color: const Color(0xFFDC2626),
          titulo:
              '${_resumen.reportesModeracion} perfil${_resumen.reportesModeracion == 1 ? '' : 'es'} reportado${_resumen.reportesModeracion == 1 ? '' : 's'}',
          subtitulo: _resumen.reportesUrgentes > 0
              ? '${_resumen.reportesUrgentes} con 5+ reportes (urgente)'
              : 'Revisá moderación',
          urgente: _resumen.reportesUrgentes > 0,
          onTap: () => widget.onIrAModulo(OwnerNavModulo.moderacion),
        ),
      );
    }

    if (alertas.isEmpty) {
      return _EstadoOkCard(
        titulo: 'Todo al día',
        subtitulo: 'No hay alertas pendientes por ahora.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requiere atención',
          style: OwnerTheme.baloo(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...alertas.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: a,
          ),
        ),
      ],
    );
  }
}

class _EstadoOkCard extends StatelessWidget {
  const _EstadoOkCard({required this.titulo, required this.subtitulo});

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: OwnerTheme.baloo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF065F46),
                  ),
                ),
                Text(
                  subtitulo,
                  style: OwnerTheme.baloo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.urgente = false,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final bool urgente;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: urgente ? color : OwnerTheme.borde,
              width: urgente ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: OwnerTheme.baloo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: OwnerTheme.baloo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: OwnerTheme.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              if (urgente)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '!',
                    style: OwnerTheme.baloo(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: OwnerTheme.textoSecundario.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.valor,
    required this.etiqueta,
    required this.onTap,
    this.compacto = false,
  });

  final IconData icon;
  final Color color;
  final String valor;
  final String etiqueta;
  final VoidCallback onTap;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OwnerTheme.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OwnerTheme.baloo(
                  fontSize: compacto ? 15 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                etiqueta,
                style: OwnerTheme.baloo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OwnerTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HerramientaCard extends StatelessWidget {
  const _HerramientaCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OwnerTheme.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: OwnerTheme.baloo(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                titulo,
                style: OwnerTheme.baloo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OwnerTheme.baloo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OwnerTheme.textoSecundario,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
