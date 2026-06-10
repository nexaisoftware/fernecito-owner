import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/owner_theme.dart';
import '../core/pagos_subseccion.dart';
import '../services/owner_service.dart';
import 'pago_detalle_screen.dart';

/// Lista de pagos filtrada por [PagosSubseccion].
class PagosScreen extends StatefulWidget {
  final PagosSubseccion subseccion;

  const PagosScreen({
    super.key,
    required this.subseccion,
  });

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _pagos = const [];
  String? _error;

  PagosSubseccion get _sub => widget.subseccion;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PagosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subseccion != widget.subseccion) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await OwnerService.instance.listarPagos(estados: _sub.estados);
      if (!mounted) return;
      setState(() {
        _pagos = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPad = isCompact ? 16.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: OwnerTheme.violetaMarca.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_pagos.length}',
                  style: OwnerTheme.baloo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: OwnerTheme.violetaMarca,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _sub.label.toLowerCase(),
                style: OwnerTheme.baloo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OwnerTheme.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: OwnerTheme.violetaMarca,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                'Error: $_error',
                                style: OwnerTheme.baloo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : _pagos.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [_EmptyState(subseccion: _sub)],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _pagos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final p = _pagos[i];
                              return _PagoCard(
                                pago: p,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PagoDetalleScreen(
                                        pago: p,
                                        soloLectura: _sub.soloLectura,
                                      ),
                                    ),
                                  );
                                  _load();
                                },
                              );
                            },
                          ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagoCard extends StatelessWidget {
  final Map<String, dynamic> pago;
  final VoidCallback onTap;

  const _PagoCard({required this.pago, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final estado = (pago['estado'] ?? '').toString();
    final tipo = (pago['tipo_solicitud'] ?? '').toString();
    final local = pago['local_username'] ?? 'sin username';
    final plan = pago['plan_solicitado'] ?? '';
    final planAnterior = pago['plan_anterior'];
    final montoUsd = pago['monto_usd'];
    final montoArs = pago['monto_ars'];

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final creado = pago['creado_en'] != null
        ? fmt.format(DateTime.parse(pago['creado_en']).toLocal())
        : '';

    final (estadoLabel, estadoColor) = _getEstadoInfo(estado);
    final (tipoLabel, tipoColor) = _getTipoInfo(tipo);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '@$local',
                      style: OwnerTheme.baloo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  _StatusBadge(label: estadoLabel, color: estadoColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    plan.toString().toUpperCase(),
                    style: OwnerTheme.baloo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: OwnerTheme.violetaMarca,
                    ),
                  ),
                  if (planAnterior != null && planAnterior.toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: OwnerTheme.textoSecundario),
                    const SizedBox(width: 6),
                    Text(
                      planAnterior.toString(),
                      style: OwnerTheme.baloo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: OwnerTheme.textoSecundario,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TypeBadge(label: tipoLabel, color: tipoColor),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OwnerTheme.texto.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'USD \$$montoUsd  •  ARS \$$montoArs',
                      style: OwnerTheme.baloo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    creado,
                    style: OwnerTheme.baloo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OwnerTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _getEstadoInfo(String estado) {
    switch (estado) {
      case 'pendiente':
        return ('Pendiente de revisión', const Color(0xFFE67E22));
      case 'aprobado':
        return ('Aprobado por owner', const Color(0xFF2980B9));
      case 'aprobado_pendiente':
        return ('Aprobado - En cola', const Color(0xFF2980B9));
      case 'aplicado':
        return ('Plan ya activo', const Color(0xFF27AE60));
      case 'rechazado':
        return ('Rechazado', const Color(0xFFC0392B));
      default:
        return (estado, Colors.grey);
    }
  }

  (String, Color) _getTipoInfo(String tipo) {
    switch (tipo) {
      case 'plan_nuevo':
        return ('Nuevo', const Color(0xFF8E44AD));
      case 'upgrade':
        return ('Upgrade', const Color(0xFF16A085));
      case 'renovacion':
        return ('Renovación', const Color(0xFF34495E));
      case 'downgrade':
        return ('Downgrade', const Color(0xFF7F8C8D));
      case 'renovacion_aprobada':
      case 'renovacion_aplicada':
        return ('Renovación', const Color(0xFF34495E));
      default:
        return (tipo, Colors.grey);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: OwnerTheme.baloo(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: OwnerTheme.baloo(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final PagosSubseccion subseccion;

  const _EmptyState({required this.subseccion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subseccion.icon,
            size: 64,
            color: OwnerTheme.textoSecundario.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros en "${subseccion.label}"',
            style: OwnerTheme.baloo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: OwnerTheme.textoSecundario,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
