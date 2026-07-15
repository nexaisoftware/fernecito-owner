import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/owner_layout.dart';
import '../core/owner_theme.dart';
import '../widgets/owner_desktop_refresh.dart';
import '../services/owner_metrics_service.dart';

class MetricasOwnerScreen extends StatefulWidget {
  const MetricasOwnerScreen({super.key});

  @override
  State<MetricasOwnerScreen> createState() => _MetricasOwnerScreenState();
}

class _MetricasOwnerScreenState extends State<MetricasOwnerScreen> {
  OwnerMetricsSnapshot _m = OwnerMetricsSnapshot.vacio();
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
      final m = await OwnerMetricsService.instance.cargar();
      if (!mounted) return;
      setState(() {
        _m = m;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las métricas: $e';
        _loading = false;
      });
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return NumberFormat('#,###').format(n);
  }

  String _fmtMoneyUsd(double v) {
    if (v >= 1000) return 'USD ${NumberFormat('#,##0').format(v)}';
    return 'USD ${v.toStringAsFixed(2)}';
  }

  String _fmtMoneyArs(double v) {
    if (v >= 1000000) {
      return '\$${NumberFormat('#,##0.0', 'es_AR').format(v / 1000000)}M';
    }
    if (v >= 1000) {
      return '\$${NumberFormat('#,##0', 'es_AR').format(v)}';
    }
    return '\$${NumberFormat('#,##0.00', 'es_AR').format(v)}';
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 20.0;

    return OwnerDesktopRefreshOverlay(
      onRefresh: _cargar,
      loading: _loading,
      child: ColoredBox(
        color: OwnerTheme.fondo,
        child: RefreshIndicator(
        onRefresh: _cargar,
        color: OwnerTheme.violetaMarca,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120),
                      _ErrorView(error: _error!, onRetry: _cargar),
                    ],
                  )
                : LayoutBuilder(
                    builder: (ctx, c) {
                      final width = c.maxWidth;
                      final cols = width >= 1100
                          ? 5
                          : width >= 820
                              ? 4
                              : width >= 560
                                  ? 3
                                  : 2;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: OwnerLayout.constrain(
                          context: ctx,
                          padding: EdgeInsets.fromLTRB(pad, 20, pad, 32),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(),
                            const SizedBox(height: 20),
                            _sectionLabel('Plataforma & cuentas', icon: Icons.groups_rounded),
                            _grid(cols: cols, items: [
                              _MiniCard(title: 'Cuentas', value: _fmt(_m.cuentasTotal), icon: Icons.groups_rounded, color: OwnerTheme.violetaMarca),
                              _MiniCard(title: 'Usuarios', value: _fmt(_m.usuarios), icon: Icons.person_outline_rounded, color: const Color(0xFF3B82F6)),
                              _MiniCard(title: 'Locales', value: _fmt(_m.locales), icon: Icons.storefront_outlined, color: const Color(0xFF10B981)),
                              _MiniCard(title: 'Verificados', value: _fmt(_m.verificados), icon: Icons.verified_outlined, color: const Color(0xFF22C55E)),
                              _MiniCard(title: 'Sin verificar', value: _fmt(_m.noVerificados), icon: Icons.help_outline_rounded, color: OwnerTheme.textoSecundario),
                            ]),
                            _sectionLabel('Pagos & ganancias', icon: Icons.payments_outlined),
                            _grid(cols: cols, items: [
                              _MiniCard(title: 'Ingresos USD', value: _fmtMoneyUsd(_m.ingresosUsd), icon: Icons.payments_outlined, color: const Color(0xFF059669), highlight: true, small: true),
                              _MiniCard(title: 'Ingresos ARS', value: _fmtMoneyArs(_m.ingresosArs), icon: Icons.currency_exchange_rounded, color: const Color(0xFF0891B2), highlight: true, small: true),
                              _MiniCard(title: 'Pagos pend.', value: _fmt(_m.pagosPendientes), icon: Icons.hourglass_top_rounded, color: const Color(0xFFE67E22)),
                              _MiniCard(title: 'Pagos OK', value: _fmt(_m.pagosAplicados), icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981)),
                              _MiniCard(title: 'Rechazados', value: _fmt(_m.pagosRechazados), icon: Icons.cancel_outlined, color: const Color(0xFFEF4444)),
                              _MiniCard(title: 'Locales pagos', value: _fmt(_m.localesPagos), icon: Icons.paid_outlined, color: const Color(0xFFF59E0B)),
                            ]),
                            const SizedBox(height: 4),
                            _sectionLabel('Distribución de planes', icon: Icons.pie_chart_outline_rounded, compact: true),
                            const SizedBox(height: 2),
                            width >= 820
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 5, child: _planPieCard()),
                                      const SizedBox(width: 12),
                                      Expanded(flex: 6, child: _planCardsGrid(cols: cols >= 4 ? 3 : 2)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _planPieCard(),
                                      const SizedBox(height: 12),
                                      _planCardsGrid(cols: cols),
                                    ],
                                  ),
                            _sectionLabel('Cartelera & eventos', icon: Icons.event_outlined),
                            _grid(cols: cols, items: [
                              _MiniCard(title: 'Eventos', value: _fmt(_m.eventosTotal), icon: Icons.event_outlined, color: const Color(0xFF6366F1)),
                              _MiniCard(title: 'Activos', value: _fmt(_m.eventosActivos), icon: Icons.bolt_rounded, color: const Color(0xFF22C55E)),
                              _MiniCard(title: 'Visitas', value: _fmt(_m.eventosVisitas), icon: Icons.visibility_outlined, color: const Color(0xFF06B6D4)),
                              _MiniCard(title: 'Reservas', value: _fmt(_m.eventosReservas), icon: Icons.bookmark_added_outlined, color: const Color(0xFF8B5CF6)),
                              _MiniCard(title: 'Tokens emit.', value: _fmt(_m.tokensEmitidos), icon: Icons.confirmation_number_outlined, color: const Color(0xFFF59E0B)),
                              _MiniCard(title: 'Canjeados', value: _fmt(_m.tokensCanjeados), icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF14B8A6)),
                            ]),
                            const SizedBox(height: 4),
                            _sectionLabel('Eventos por jerarquía', icon: Icons.stacked_bar_chart_rounded, compact: true),
                            const SizedBox(height: 2),
                            _jerarquiasCard(),
                            _sectionLabel('Engagement', icon: Icons.favorite_outline_rounded),
                            _grid(cols: cols, items: [
                              _MiniCard(title: 'Reviews', value: _fmt(_m.reviewsTotal), icon: Icons.rate_review_outlined, color: const Color(0xFF8B5CF6)),
                              _MiniCard(title: '★ Promedio', value: _m.reviewsPromedio.toStringAsFixed(2), icon: Icons.star_outline_rounded, color: const Color(0xFFF59E0B)),
                              _MiniCard(title: 'Promos', value: _fmt(_m.promosTotal), icon: Icons.local_offer_outlined, color: const Color(0xFFEF4444)),
                              _MiniCard(title: 'Promos activas', value: _fmt(_m.promosActivas), icon: Icons.flash_on_outlined, color: const Color(0xFFFB923C)),
                              _MiniCard(title: 'Cupos usados', value: _fmt(_m.promosCuposUsados), icon: Icons.confirmation_number_outlined, color: const Color(0xFF14B8A6)),
                            ]),
                            _sectionLabel('Flyers IA', icon: Icons.auto_awesome_outlined),
                            _grid(cols: cols, items: [
                              _MiniCard(title: 'Flyers', value: _fmt(_m.flyersTotal), icon: Icons.image_outlined, color: const Color(0xFF8B5CF6)),
                              _MiniCard(title: 'Flyers mes', value: _fmt(_m.flyersEsteMes), icon: Icons.calendar_today_outlined, color: const Color(0xFFEC4899), highlight: true),
                              _MiniCard(title: 'Entregados', value: _fmt(_m.flyersEntregados), icon: Icons.check_circle_outline, color: const Color(0xFF22C55E)),
                              _MiniCard(title: 'Tasa entrega', value: '${_m.flyersTasaEntrega.toStringAsFixed(0)}%', icon: Icons.trending_up_rounded, color: const Color(0xFF14B8A6)),
                              _MiniCard(title: 'Reintentos', value: _fmt(_m.flyersRetries), icon: Icons.replay_rounded, color: const Color(0xFFE67E22)),
                            ]),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _header() {
    final gen = _m.generadoEn;
    final hora = gen != null ? DateFormat('HH:mm').format(gen.toLocal()) : '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas',
          style: OwnerTheme.baloo(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: OwnerTheme.texto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Actualizado $hora',
          style: OwnerTheme.baloo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: OwnerTheme.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, {IconData? icon, bool compact = false}) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 20, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 15 : 17,
              color: OwnerTheme.violetaMarca.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            title,
            style: OwnerTheme.baloo(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
              color: OwnerTheme.texto,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: OwnerTheme.borde, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _grid({required int cols, required List<Widget> items}) {
    return LayoutBuilder(builder: (ctx, c) {
      const gap = 10.0;
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items.map((it) => SizedBox(width: w, child: it)).toList(),
      );
    });
  }

  // ─── Planes: pie chart compacto sin overflow ──────────────────────────────
  Widget _planPieCard() {
    final data = <_PlanData>[
      _PlanData('Sin verificar', _m.planSinVerificar, const Color(0xFF94A3B8)),
      if (_m.planGratis > 0)
        _PlanData('Gratis (verif.)', _m.planGratis, const Color(0xFF6B7280)),
      _PlanData('Standard', _m.planStandard, const Color(0xFF6366F1)),
      _PlanData('Plus', _m.planPlus, const Color(0xFF0891B2)),
      _PlanData('Premium', _m.planPremium, const Color(0xFFF59E0B)),
      _PlanData('Pionero', _m.planPionero, const Color(0xFF22C55E)),
    ].where((d) => d.count > 0).toList();

    final total = _m.locales > 0 ? _m.locales : data.fold<int>(0, (a, b) => a + b.count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwnerTheme.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerTheme.borde),
      ),
      child: data.isEmpty
          ? const SizedBox(height: 200, child: Center(child: Text('Sin datos')))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Locales por plan activo (verificados) y cuentas sin verificar',
                  textAlign: TextAlign.center,
                  style: OwnerTheme.baloo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: OwnerTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: data.map((d) {
                            return PieChartSectionData(
                              value: d.count.toDouble(),
                              color: d.color,
                              radius: 50,
                              showTitle: false,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 48,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: OwnerTheme.baloo(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: OwnerTheme.texto,
                            ),
                          ),
                          Text(
                            'locales',
                            style: OwnerTheme.baloo(
                              fontSize: 11,
                              color: OwnerTheme.textoSecundario,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: data.map((d) {
                    final pct = ((d.count / total) * 100).toStringAsFixed(0);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: d.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${d.label} · ${d.count} ($pct%)',
                          style: OwnerTheme.baloo(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _planCardsGrid({required int cols}) {
    final items = [
      _MiniCard(
          title: 'Sin verificar',
          value: _fmt(_m.planSinVerificar),
          icon: Icons.person_off_outlined,
          color: const Color(0xFF94A3B8)),
      if (_m.planGratis > 0)
        _MiniCard(
            title: 'Gratis verif.',
            value: _fmt(_m.planGratis),
            icon: Icons.card_giftcard,
            color: const Color(0xFF6B7280)),
      _MiniCard(
          title: 'Standard',
          value: _fmt(_m.planStandard),
          icon: Icons.trending_up,
          color: const Color(0xFF6366F1)),
      _MiniCard(
          title: 'Plus',
          value: _fmt(_m.planPlus),
          icon: Icons.star,
          color: const Color(0xFF0891B2)),
      _MiniCard(
          title: 'Premium',
          value: _fmt(_m.planPremium),
          icon: Icons.workspace_premium,
          color: const Color(0xFFF59E0B)),
      _MiniCard(
          title: 'Pionero',
          value: _fmt(_m.planPionero),
          icon: Icons.emoji_events,
          color: const Color(0xFF22C55E)),
      _MiniCard(
          title: 'Pagos',
          value: _fmt(_m.localesPagos),
          icon: Icons.paid,
          color: const Color(0xFF10B981)),
    ];
    return _grid(cols: cols, items: items);
  }

  // ─── Jerarquías card ──────────────────────────────────────────────────────
  Widget _jerarquiasCard() {
    final items = [
      ('Top Ultra', _m.jerarqUltra, const Color(0xFFEF4444), Icons.local_fire_department),
      ('Top', _m.jerarqTop, const Color(0xFFF59E0B), Icons.bolt),
      ('Rec. Fernecito', _m.jerarqReco, const Color(0xFF8B5CF6), Icons.thumb_up),
      ('Gratis', _m.jerarqGratis, const Color(0xFF94A3B8), Icons.celebration_outlined),
      ('Normal', _m.jerarqNormal, const Color(0xFF6B7280), Icons.event_outlined),
    ];
    final total = items.fold<int>(0, (a, b) => a + b.$2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerTheme.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwnerTheme.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final it in items) ...[
            _BarRow(label: it.$1, count: it.$2, total: total, color: it.$3, icon: it.$4),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ═══════════════════════════════════════════════════════════════════════════

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
  final bool small;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwnerTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.45) : OwnerTheme.borde,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: OwnerTheme.baloo(
                fontSize: small ? 16 : 20,
                fontWeight: FontWeight.w900,
                color: OwnerTheme.texto,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OwnerTheme.baloo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: OwnerTheme.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _BarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: OwnerTheme.fondo,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String label;
  final int count;
  final Color color;
  _PlanData(this.label, this.count, this.color);
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: OwnerTheme.baloo(fontSize: 14, color: OwnerTheme.textoSecundario),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
