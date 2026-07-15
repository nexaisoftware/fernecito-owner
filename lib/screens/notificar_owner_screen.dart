import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/owner_layout.dart';
import '../core/owner_theme.dart';
import '../models/push_filtros.dart';
import '../services/owner_service.dart';
import '../widgets/owner_desktop_refresh.dart';
import '../widgets/owner_refreshable.dart';
import '../widgets/owner_subpage_scaffold.dart';
import '../widgets/push_app_icon.dart';
import '../widgets/push_filtros_panel.dart';

/// Panel "Notificar": el owner escribe y envía una notificación push.
class NotificarOwnerScreen extends StatefulWidget {
  const NotificarOwnerScreen({super.key});

  @override
  State<NotificarOwnerScreen> createState() => _NotificarOwnerScreenState();
}

class _NotificarOwnerScreenState extends State<NotificarOwnerScreen> {
  final _tituloCtrl = TextEditingController();
  final _cuerpoCtrl = TextEditingController();
  bool _enviando = false;
  String _target = 'usuarios';
  PushFiltros _filtros = const PushFiltros();
  late Future<List<Map<String, dynamic>>> _historial;

  static const _maxTitulo = 80;
  static const _maxCuerpo = 240;

  @override
  void initState() {
    super.initState();
    _historial = OwnerService.instance.listarEnviosPush();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _cuerpoCtrl.dispose();
    super.dispose();
  }

  void _refrescarHistorial() {
    setState(() {
      _historial = OwnerService.instance.listarEnviosPush();
    });
  }

  bool get _valido =>
      _tituloCtrl.text.trim().length >= 3 &&
      _cuerpoCtrl.text.trim().length >= 3;

  InputDecoration _input(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: OwnerTheme.textoSecundario,
      ),
    );
  }

  Future<void> _confirmarYEnviar() async {
    final titulo = _tituloCtrl.text.trim();
    final cuerpo = _cuerpoCtrl.text.trim();
    if (titulo.length < 3 || cuerpo.length < 3) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            PushAppIcon(target: _target, size: 44, borderRadius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Confirmar envío',
                style: OwnerTheme.baloo(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          pushTargetConfirmacion(_target, filtros: _filtros),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: OwnerTheme.textoSecundario,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _enviando = true);
    try {
      final res = await OwnerService.instance.enviarPushMasiva(
        titulo: titulo,
        cuerpo: cuerpo,
        target: _target,
        filtros: _filtros,
      );
      if (!mounted) return;
      final enviados = res['exitosos'] ?? 0;
      final total = res['destinatarios'] ?? 0;
      _mostrarSnack('Enviada a $enviados de $total dispositivos ✅', ok: true);
      _tituloCtrl.clear();
      _cuerpoCtrl.clear();
      _refrescarHistorial();
    } on FunctionException catch (e) {
      if (!mounted) return;
      final detalle = e.details;
      final msg = (detalle is Map && detalle['error'] is String)
          ? detalle['error'] as String
          : 'No se pudo enviar. Intentá de nuevo.';
      _mostrarSnack(msg, ok: false);
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Error inesperado al enviar.', ok: false);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarSnack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? OwnerTheme.violetaMarca : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OwnerSubpageScaffold(
      onRefresh: () async {
        _refrescarHistorial();
        await _historial;
      },
      body: OwnerRefreshScroll(
        onRefresh: () async {
          _refrescarHistorial();
          await _historial;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
          Text(
            'Crear notificación push',
            style: OwnerTheme.baloo(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Enviá un aviso a usuarios, locales o ambos. Ideal para promos y recordatorios.',
            style: OwnerTheme.baloo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: OwnerTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¿A quién?',
            style: OwnerTheme.baloo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: OwnerTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'usuarios',
                label: Text('Usuarios', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                icon: Image.asset(PushAppAssets.usuarios, width: 18, height: 18),
              ),
              ButtonSegment(
                value: 'locales',
                label: Text('Locales', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                icon: Image.asset(PushAppAssets.locales, width: 18, height: 18),
              ),
              ButtonSegment(
                value: 'ambos',
                label: Text('Ambos', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                icon: PushAppIcon(target: 'ambos', size: 18, borderRadius: 5, overlap: 6),
              ),
            ],
            selected: {_target},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _target = s.first),
          ),
          if (_filtros.activo) ...[
            const SizedBox(height: 10),
            Text(
              'Destino: ${_filtros.resumenCompacto(target: _target)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OwnerTheme.violetaMarca,
              ),
            ),
          ],
          const SizedBox(height: 16),
          PushFiltrosPanel(
            target: _target,
            filtros: _filtros,
            onChanged: (f) => setState(() => _filtros = f),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _tituloCtrl,
                    maxLength: _maxTitulo,
                    autocorrect: false,
                    enableSuggestions: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    inputFormatters: [LengthLimitingTextInputFormatter(_maxTitulo)],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: _input('Título', '¡Es viernes! 🎉'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cuerpoCtrl,
                    maxLength: _maxCuerpo,
                    maxLines: 3,
                    autocorrect: false,
                    enableSuggestions: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    inputFormatters: [LengthLimitingTextInputFormatter(_maxCuerpo)],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: _input(
                      'Mensaje',
                      'Miles de planes cerca tuyo te esperan…',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vista previa',
            style: OwnerTheme.baloo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: OwnerTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          _PreviewPush(
            target: _target,
            titulo: _tituloCtrl.text.trim().isEmpty
                ? 'Título de la notificación'
                : _tituloCtrl.text.trim(),
            cuerpo: _cuerpoCtrl.text.trim().isEmpty
                ? 'Así se va a ver el mensaje en el celular.'
                : _cuerpoCtrl.text.trim(),
          ),
          const SizedBox(height: 24),
          _AlcanceBadge(target: _target, filtros: _filtros),
          const SizedBox(height: 12),
          OwnerAdaptiveButton(
            onPressed: (_valido && !_enviando) ? _confirmarYEnviar : null,
            loading: _enviando,
            icon: const Icon(Icons.send_rounded),
            label: _enviando
                ? 'Enviando…'
                : (_filtros.activo ? 'Enviar segmentada' : 'Enviar a todos'),
          ),
          const SizedBox(height: 32),
          Text(
            'Enviadas recientemente',
            style: OwnerTheme.baloo(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _historial,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Text(
                  'Todavía no enviaste ninguna notificación.',
                  style: OwnerTheme.baloo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: OwnerTheme.textoSecundario,
                  ),
                );
              }
              return Column(children: items.map(_itemHistorial).toList());
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget _itemHistorial(Map<String, dynamic> e) {
    final titulo = (e['titulo'] ?? '').toString();
    final cuerpo = (e['cuerpo'] ?? '').toString();
    final exitosos = e['exitosos'] ?? 0;
    final destinatarios = e['destinatarios'] ?? 0;
    final segmento = (e['segmento'] ?? 'usuarios').toString();
    final segLabel = pushSegmentoLegible(segmento);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: OwnerTheme.baloo(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: OwnerTheme.violetaMarca.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    segLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: OwnerTheme.baloo(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: OwnerTheme.violetaMarca,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              cuerpo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OwnerTheme.baloo(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: OwnerTheme.textoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: OwnerTheme.violetaMarca),
                const SizedBox(width: 4),
                Text(
                  '$exitosos de $destinatarios',
                  style: OwnerTheme.baloo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: OwnerTheme.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlcanceBadge extends StatefulWidget {
  const _AlcanceBadge({required this.target, required this.filtros});

  final String target;
  final PushFiltros filtros;

  @override
  State<_AlcanceBadge> createState() => _AlcanceBadgeState();
}

class _AlcanceBadgeState extends State<_AlcanceBadge> {
  int? _alcance;
  bool _cargando = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _programarConsulta();
  }

  @override
  void didUpdateWidget(covariant _AlcanceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target ||
        oldWidget.filtros != widget.filtros) {
      _programarConsulta();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _programarConsulta() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _consultar);
  }

  Future<void> _consultar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final n = await OwnerService.instance.contarAlcancePush(
        target: widget.target,
        filtros: widget.filtros,
      );
      if (!mounted) return;
      setState(() {
        _alcance = n;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alcance = null;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.filtros.activo ? 'Alcance estimado' : 'Dispositivos alcanzables';

    return Align(
      alignment: OwnerLayout.isDesktop(context)
          ? Alignment.centerLeft
          : Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: OwnerTheme.violetaMarca,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cargando)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.devices_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _cargando
                  ? '$label…'
                  : _alcance == null
                      ? 'No se pudo calcular alcance'
                      : '≈ $_alcance dispositivo${_alcance == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPush extends StatelessWidget {
  const _PreviewPush({
    required this.target,
    required this.titulo,
    required this.cuerpo,
  });

  final String target;
  final String titulo;
  final String cuerpo;

  String get _appLabel => pushTargetAppLabel(target);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerTheme.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PushAppIcon(target: target, size: 38, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_appLabel · ahora',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OwnerTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  cuerpo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: OwnerTheme.texto,
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
