import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/owner_service.dart';

class PagoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> pago;
  final bool soloLectura;

  const PagoDetalleScreen({
    super.key,
    required this.pago,
    this.soloLectura = false,
  });

  @override
  State<PagoDetalleScreen> createState() => _PagoDetalleScreenState();
}

class _PagoDetalleScreenState extends State<PagoDetalleScreen> {
  String? _signedUrl;
  bool _loadingUrl = true;
  bool _procesando = false;
  final _notas = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final path = widget.pago['comprobante_url']?.toString();
    if (path == null || path.isEmpty) {
      setState(() => _loadingUrl = false);
      return;
    }
    final url = await OwnerService.instance.urlComprobante(path);
    if (!mounted) return;
    setState(() {
      _signedUrl = url;
      _loadingUrl = false;
    });
  }

  Future<void> _confirmar({required bool aprobar}) async {
    final motivo = _notas.text.trim();
    if (!aprobar && motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motivo de rechazo requerido')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(aprobar ? '¿Aprobar esta solicitud?' : '¿Rechazar solicitud?'),
        content: Text(aprobar
            ? 'Se activará el plan para el local según el tipo de solicitud.'
            : 'El local recibirá una notificación con el motivo del rechazo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(aprobar ? 'Sí, aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    try {
      final pagoId = widget.pago['id'].toString();
      final res = aprobar
          ? await OwnerService.instance.aprobarPago(pagoId, notas: motivo.isEmpty ? null : motivo)
          : await OwnerService.instance.rechazarPago(pagoId, motivo: motivo);
      if (!mounted) return;
      final ok = res['ok'] == true || (res['resultado'] is Map && (res['resultado'] as Map)['ok'] == true);
      if (!ok) {
        final code = res['code'] ?? (res['resultado'] is Map ? (res['resultado'] as Map)['code'] : null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo completar: ${code ?? 'error desconocido'}')),
        );
        return;
      }
      final resultado = res['resultado'];
      String msg = 'Acción realizada';
      if (resultado is Map) {
        if (resultado['aplicado_inmediato'] == true) {
          msg = 'Plan activado de inmediato';
        } else if (resultado['aplica_desde'] != null) {
          msg = 'Aprobado — se aplicará al vencer el plan actual';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pago;
    final estado = (p['estado'] ?? '').toString();
    final isHistorial = estado == 'aplicado' || estado == 'rechazado';
    final esPendiente = estado == 'pendiente';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        elevation: 0,
        title: Text('Solicitud de @${p['local_username'] ?? ''}'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          final infoCol = _InfoColumn(
            pago: p,
            notasController: _notas,
            procesando: _procesando,
            soloLectura: widget.soloLectura,
            esPendiente: esPendiente,
            isHistorial: isHistorial,
            onConfirmar: _confirmar,
          );
          final comprobante = _ComprobantePanel(
            signedUrl: _signedUrl,
            loading: _loadingUrl,
            comprobantePath: p['comprobante_url']?.toString(),
            estado: estado,
          );

          if (isDesktop) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: info
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: infoCol,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Columna derecha: comprobante (fija, alta)
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: constraints.maxHeight - 40,
                      child: comprobante,
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile: stack vertical
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 480,
                  child: comprobante,
                ),
                const SizedBox(height: 16),
                infoCol,
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COLUMNA IZQUIERDA: info de la solicitud + acciones
// ═══════════════════════════════════════════════════════════════════════════

class _InfoColumn extends StatelessWidget {
  final Map<String, dynamic> pago;
  final TextEditingController notasController;
  final bool procesando;
  final bool soloLectura;
  final bool esPendiente;
  final bool isHistorial;
  final Future<void> Function({required bool aprobar}) onConfirmar;

  const _InfoColumn({
    required this.pago,
    required this.notasController,
    required this.procesando,
    required this.soloLectura,
    required this.esPendiente,
    required this.isHistorial,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final p = pago;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final creado = p['creado_en'] != null ? fmt.format(DateTime.parse(p['creado_en']).toLocal()) : '-';
    final revisado = p['revisado_en'] != null ? fmt.format(DateTime.parse(p['revisado_en']).toLocal()) : null;
    final aplicaDesde = p['aplica_desde'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(p['aplica_desde']).toLocal())
        : null;
    final estado = (p['estado'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con local + chips de estado / tipo / plan
        _HeaderCard(pago: p),

        const SizedBox(height: 16),

        _Section(
          icon: Icons.receipt_long_rounded,
          title: 'Detalle del pago',
          child: Column(
            children: [
              _RowMonto(label: 'Monto USD', value: '\$${p['monto_usd']}'),
              const _DividerSoft(),
              _RowMonto(label: 'Monto ARS', value: '\$${p['monto_ars']}'),
              const _DividerSoft(),
              _RowMonto(
                label: 'Cotización blue',
                value: '\$${p['cotizacion_blue']}',
                muted: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _Section(
          icon: Icons.event_rounded,
          title: 'Fechas',
          child: Column(
            children: [
              _RowInfo('Solicitud enviada', creado),
              if (revisado != null) ...[
                const _DividerSoft(),
                _RowInfo(estado == 'rechazado' ? 'Rechazado el' : 'Aprobado el', revisado),
              ],
              if (aplicaDesde != null) ...[
                const _DividerSoft(),
                _RowInfo('Se aplica al vencer ($aplicaDesde)', '', highlight: true, valueAsLabel: true),
              ],
            ],
          ),
        ),

        if (p['notas'] != null && p['notas'].toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            icon: Icons.sticky_note_2_rounded,
            title: 'Notas',
            child: Text(
              p['notas'].toString(),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],

        // Acciones
        if (!soloLectura && esPendiente) ...[
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFEAE6F5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: notasController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas / motivo (obligatorio para rechazar)',
                      hintText: 'Ej: comprobante no coincide con el monto…',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFFAFAFC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: procesando ? null : () => onConfirmar(aprobar: false),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0392B),
                            side: const BorderSide(color: Color(0xFFC0392B)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: procesando ? null : () => onConfirmar(aprobar: true),
                          icon: procesando
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded),
                          label: Text(procesando ? 'Procesando…' : 'Aprobar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        if (isHistorial)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              estado == 'aplicado'
                  ? '✅ Este plan ya está activo en la cuenta del local.'
                  : '❌ Esta solicitud fue rechazada.',
              style: TextStyle(
                color: estado == 'aplicado' ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER CARD: username + chips de estado, tipo y plan
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> pago;

  const _HeaderCard({required this.pago});

  @override
  Widget build(BuildContext context) {
    final estado = (pago['estado'] ?? '').toString();
    final tipo = (pago['tipo_solicitud'] ?? '').toString();
    final plan = (pago['plan_solicitado'] ?? '').toString();
    final planAnterior = (pago['plan_anterior'] ?? '').toString();
    final local = pago['local_username'] ?? '';

    final (estLabel, estColor) = switch (estado) {
      'pendiente' => ('Pendiente', const Color(0xFFE67E22)),
      'aprobado_pendiente' => ('Agendado', const Color(0xFF2980B9)),
      'aplicado' => ('Activo', const Color(0xFF27AE60)),
      'rechazado' => ('Rechazado', const Color(0xFFC0392B)),
      _ => (estado, Colors.grey),
    };

    final (tipoLabel, tipoColor, tipoIcon) = switch (tipo) {
      'plan_nuevo' => ('Plan nuevo', const Color(0xFF8E44AD), Icons.fiber_new_rounded),
      'upgrade' => ('Upgrade', const Color(0xFF2980B9), Icons.arrow_upward_rounded),
      'renovacion' => ('Renovación', const Color(0xFF16A085), Icons.refresh_rounded),
      'downgrade' => ('Downgrade', const Color(0xFFE67E22), Icons.arrow_downward_rounded),
      _ => (tipo, Colors.grey, Icons.help_outline),
    };

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFEAE6F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A2EFF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF5A2EFF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$local',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Text(
                        'Local solicitante',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _Chip(label: estLabel, color: estColor, filled: true),
                _Chip(label: tipoLabel, color: tipoColor, icon: tipoIcon),
                _PlanChip(plan: plan),
                if (planAnterior.isNotEmpty && planAnterior != 'null')
                  _Chip(
                    label: 'Desde: $planAnterior',
                    color: Colors.grey.shade600,
                    icon: Icons.history,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const _Chip({required this.label, required this.color, this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String plan;
  const _PlanChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (plan.toLowerCase()) {
      'gratis' => (const Color(0xFF95A5A6), 'GRATIS'),
      'standard' => (const Color(0xFF5A2EFF), 'STANDARD'),
      'plus' => (const Color(0xFF0891B2), 'PLUS'),
      'premium' => (const Color(0xFFF59E0B), 'PREMIUM'),
      'pionero' => (const Color(0xFF16A34A), 'PIONERO'),
      _ => (Colors.grey, plan.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION wrapper
// ═══════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFEAE6F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF5A2EFF)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF44425C)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DividerSoft extends StatelessWidget {
  const _DividerSoft();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 12, thickness: 1, color: Color(0xFFF1EFFB));
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool valueAsLabel;

  const _RowInfo(this.label, this.value, {this.highlight = false, this.valueAsLabel = false});

  @override
  Widget build(BuildContext context) {
    if (valueAsLabel) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: highlight ? const Color(0xFF5A2EFF) : Colors.black87,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? const Color(0xFF5A2EFF) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowMonto extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _RowMonto({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: muted ? Colors.black45 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: muted ? 14 : 17,
              fontWeight: muted ? FontWeight.w600 : FontWeight.w800,
              color: muted ? Colors.black54 : const Color(0xFF44425C),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL DEL COMPROBANTE (derecha en desktop, arriba en mobile)
// ═══════════════════════════════════════════════════════════════════════════

class _ComprobantePanel extends StatelessWidget {
  final String? signedUrl;
  final bool loading;
  final String? comprobantePath;
  final String estado;

  const _ComprobantePanel({
    required this.signedUrl,
    required this.loading,
    required this.comprobantePath,
    required this.estado,
  });

  bool get _isPdf {
    final p = (comprobantePath ?? signedUrl ?? '').toLowerCase();
    return p.contains('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE6F5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: const Color(0xFFF8F7FB),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Icon(
                  _isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  size: 18,
                  color: const Color(0xFF5A2EFF),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comprobante de transferencia',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF44425C)),
                ),
                const Spacer(),
                if (signedUrl != null) ...[
                  IconButton(
                    tooltip: 'Copiar URL',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: signedUrl!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL copiada')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Abrir en nueva pestaña',
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    onPressed: () {
                      // En web: window.open. Por compat, usamos url_launcher si existe;
                      // como fallback usamos el evento de Anchor.
                      _abrirEnNuevaTab(signedUrl!);
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenido
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (signedUrl == null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.broken_image_rounded, size: 56, color: Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se pudo cargar el comprobante',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'El archivo puede estar dañado, eliminado, o no tenés permiso para verlo. Si el local recién lo subió, esperá unos segundos y refrescá.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isPdf) {
      // PDF en iframe via HtmlElementView no es trivial sin dependencias;
      // como fallback robusto mostramos un placeholder grande con CTA.
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 100, color: Color(0xFFE74C3C)),
            const SizedBox(height: 16),
            const Text(
              'Comprobante en PDF',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Abrí el archivo en una nueva pestaña para revisarlo.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir PDF'),
              onPressed: () => _abrirEnNuevaTab(signedUrl!),
            ),
          ],
        ),
      );
    }

    // Imagen: zoomable + fit contain
    return InteractiveViewer(
      maxScale: 5,
      minScale: 0.8,
      child: Center(
        child: Image.network(
          signedUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (ctx, child, prog) {
            if (prog == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: prog.expectedTotalBytes != null
                    ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (ctx, err, st) => const Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'Error al renderizar la imagen.\nProbá abrir en nueva pestaña.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirEnNuevaTab(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } else {
      await Clipboard.setData(ClipboardData(text: url));
    }
  }
}
