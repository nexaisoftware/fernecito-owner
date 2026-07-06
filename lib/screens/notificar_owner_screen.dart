import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/owner_theme.dart';
import '../services/owner_service.dart';
import '../widgets/app_logo_image.dart';

/// Panel "Notificar": el owner escribe y envía una notificación push a todos
/// los usuarios de la app. Muestra un preview de cómo llega y el historial.
class NotificarOwnerScreen extends StatefulWidget {
  const NotificarOwnerScreen({super.key});

  @override
  State<NotificarOwnerScreen> createState() => _NotificarOwnerScreenState();
}

class _NotificarOwnerScreenState extends State<NotificarOwnerScreen> {
  final _tituloCtrl = TextEditingController();
  final _cuerpoCtrl = TextEditingController();
  bool _enviando = false;
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

  Future<void> _confirmarYEnviar() async {
    final titulo = _tituloCtrl.text.trim();
    final cuerpo = _cuerpoCtrl.text.trim();
    if (titulo.length < 3 || cuerpo.length < 3) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Enviar a todos?', style: OwnerTheme.baloo(fontWeight: FontWeight.w800)),
        content: Text(
          'Se enviará esta notificación push a todos los usuarios con la app '
          'instalada. Esta acción no se puede deshacer.',
          style: OwnerTheme.baloo(fontSize: 14, fontWeight: FontWeight.w500, color: OwnerTheme.textoSecundario),
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
      final res = await OwnerService.instance.enviarPushMasiva(titulo: titulo, cuerpo: cuerpo);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Row(
          children: [
            Icon(Icons.campaign_rounded, color: OwnerTheme.violetaMarca, size: 26),
            const SizedBox(width: 10),
            Text('Crear notificación push',
                style: OwnerTheme.baloo(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enviá un aviso a todos los usuarios de Fernecito App. Ideal para '
          'promos, recordatorios y planes del finde.',
          style: OwnerTheme.baloo(fontSize: 14, fontWeight: FontWeight.w500, color: OwnerTheme.textoSecundario),
        ),
        const SizedBox(height: 24),

        // Compositor
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _tituloCtrl,
                  maxLength: _maxTitulo,
                  inputFormatters: [LengthLimitingTextInputFormatter(_maxTitulo)],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: '¡Es viernes! 🎉',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cuerpoCtrl,
                  maxLength: _maxCuerpo,
                  maxLines: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(_maxCuerpo)],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    hintText: 'Miles de planes cerca tuyo te esperan. Abrí la app y no te quedes afuera 👀',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text('Vista previa', style: OwnerTheme.baloo(fontSize: 13, fontWeight: FontWeight.w800, color: OwnerTheme.textoSecundario)),
        const SizedBox(height: 8),
        _PreviewPush(
          titulo: _tituloCtrl.text.trim().isEmpty ? 'Título de la notificación' : _tituloCtrl.text.trim(),
          cuerpo: _cuerpoCtrl.text.trim().isEmpty ? 'Así se va a ver el mensaje en el celular del usuario.' : _cuerpoCtrl.text.trim(),
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: (_valido && !_enviando) ? _confirmarYEnviar : null,
          icon: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: Text(_enviando ? 'Enviando…' : 'Enviar a todos'),
        ),
        const SizedBox(height: 32),

        Text('Enviadas recientemente', style: OwnerTheme.baloo(fontSize: 16, fontWeight: FontWeight.w800)),
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
              return Text('Todavía no enviaste ninguna notificación.',
                  style: OwnerTheme.baloo(fontSize: 14, fontWeight: FontWeight.w500, color: OwnerTheme.textoSecundario));
            }
            return Column(
              children: items.map(_itemHistorial).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _itemHistorial(Map<String, dynamic> e) {
    final titulo = (e['titulo'] ?? '').toString();
    final cuerpo = (e['cuerpo'] ?? '').toString();
    final exitosos = e['exitosos'] ?? 0;
    final destinatarios = e['destinatarios'] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: OwnerTheme.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(cuerpo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OwnerTheme.baloo(fontSize: 13, fontWeight: FontWeight.w500, color: OwnerTheme.textoSecundario)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: OwnerTheme.violetaMarca),
                const SizedBox(width: 4),
                Text('$exitosos de $destinatarios',
                    style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w700, color: OwnerTheme.textoSecundario)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview de cómo se ve la notificación en el celular del usuario.
class _PreviewPush extends StatelessWidget {
  const _PreviewPush({required this.titulo, required this.cuerpo});

  final String titulo;
  final String cuerpo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwnerTheme.borde),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const AppLogoImage(size: 38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Fernecito App',
                        style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: OwnerTheme.textoSecundario)),
                    Text('  ·  ahora',
                        style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w500, color: OwnerTheme.textoSecundario)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(titulo, style: OwnerTheme.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(cuerpo, style: OwnerTheme.baloo(fontSize: 13, fontWeight: FontWeight.w500, color: OwnerTheme.texto)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
