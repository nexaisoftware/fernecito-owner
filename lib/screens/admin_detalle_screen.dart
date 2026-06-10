import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/motivos_pausa_cuenta.dart';
import '../services/owner_admin_service.dart';

/// Detalle completo de un local o usuario con:
/// - Info personal en tabla
/// - Cards de stats (activo desde, plan, cantidades)
/// - Botones de acción: Reset password, Pausar/Reactivar, Eliminar
/// - Dropdown con publicaciones (eventos para locales, reviews/tokens para usuarios)
class AdminDetalleScreen extends StatefulWidget {
  final String tipo; // 'local' | 'usuario'
  final String targetId;
  final String nombreInicial;

  const AdminDetalleScreen({
    super.key,
    required this.tipo,
    required this.targetId,
    required this.nombreInicial,
  });

  @override
  State<AdminDetalleScreen> createState() => _AdminDetalleScreenState();
}

class _AdminDetalleScreenState extends State<AdminDetalleScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _procesandoAccion = false;

  bool get _esLocal => widget.tipo == 'local';

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
      final data = _esLocal
          ? await OwnerAdminService.instance.detalleLocal(widget.targetId)
          : await OwnerAdminService.instance.detalleUsuario(widget.targetId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _perfil =>
      _data?['perfil'] is Map ? Map<String, dynamic>.from(_data!['perfil'] as Map) : {};
  Map<String, dynamic> get _stats =>
      _data?['stats'] is Map ? Map<String, dynamic>.from(_data!['stats'] as Map) : {};
  String get _email => _data?['email']?.toString() ?? '-';

  bool get _estaPausada => (_perfil['estado_cuenta']?.toString() ?? 'activa') == 'pausada';

  Future<void> _resetPassword() async {
    // Menú de elección: email oficial vs pass temporal generada por owner.
    final opcion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text('Ayuda con contraseña',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Elegí cómo querés ayudar al usuario',
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.black54)),
              const SizedBox(height: 16),
              _OpcionResetCard(
                icono: Icons.lock_reset,
                color: const Color(0xFF3B82F6),
                titulo: 'Generar pass temporal',
                bullets: const [
                  '⚡ Instantáneo, no depende del email',
                  '🔐 Pass random segura (12 chars)',
                  '📋 La copiás y se la mandás por soporte',
                  '🔄 El usuario la cambia al entrar',
                ],
                recomendada: true,
                onTap: () => Navigator.pop(ctx, 'temporal'),
              ),
              const SizedBox(height: 10),
              _OpcionResetCard(
                icono: Icons.email_outlined,
                color: const Color(0xFF8B5CF6),
                titulo: 'Mandar email de reset',
                bullets: const [
                  '📧 Email oficial de Supabase con código',
                  '⚠️ Solo funciona si tenés SMTP configurado',
                  '🐌 Depende de que el user revise spam',
                ],
                onTap: () => Navigator.pop(ctx, 'email'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (opcion == 'email') {
      await _resetPasswordEmail();
    } else if (opcion == 'temporal') {
      await _generarPassTemporal();
    }
  }

  Future<void> _resetPasswordEmail() async {
    setState(() => _procesandoAccion = true);
    try {
      final res = await OwnerAdminService.instance.resetPassword(widget.targetId);
      _showResult(res, 'Email de reset enviado a $_email');
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  Future<void> _generarPassTemporal() async {
    setState(() => _procesandoAccion = true);
    try {
      final res = await OwnerAdminService.instance.setPasswordTemporal(widget.targetId);
      if (!mounted) return;
      if (res['ok'] != true) {
        _showResult(res, '');
        return;
      }
      final pass = res['password_temporal']?.toString() ?? '';
      await _mostrarDialogPassGenerada(pass);
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  Future<void> _mostrarDialogPassGenerada(String pass) async {
    final username = _perfil['local_username']?.toString() ??
        _perfil['username']?.toString() ??
        '';
    final mensajeTemplate =
        '¡Hola @$username! 👋\n\n'
        'Soy del equipo oficial de Fernecito. Te genero una contraseña temporal '
        'para que puedas entrar:\n\n'
        '🔑 $pass\n\n'
        'Importante:\n'
        '• Es una clave de un solo uso, cambiala apenas entres desde '
        '"Mi cuenta" → "Cambiar contraseña".\n'
        '• Si no fuiste vos quien pidió ayuda, escribime de vuelta YA.\n\n'
        '— Equipo Fernecito 🥃';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Color(0xFF15803D), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Pass temporal generada',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        pass,
                        style: GoogleFonts.robotoMono(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF78350F),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFFB45309)),
                      tooltip: 'Copiar solo la pass',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: pass));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pass copiada')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Esta pass NO se vuelve a mostrar. Copiala y mandásela al usuario por soporte ahora.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mensajeTemplate));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mensaje copiado — pegalo en WhatsApp/email'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy, size: 18),
                label: const Text('Copiar mensaje completo'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A2EFF),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePausar() async {
    final pausar = !_estaPausada;
    String? notaInterna;
    String? motivoPublico;
    if (pausar) {
      final datos = await _pedirDatosPausa();
      if (datos == null) return;
      notaInterna = datos['nota'];
      motivoPublico = datos['motivo_publico'];
    } else {
      final ok = await _confirmar(
        'Reactivar cuenta',
        'La cuenta volverá a tener acceso completo a la app. ¿Continuar?',
        'Reactivar',
      );
      if (!ok) return;
    }
    setState(() => _procesandoAccion = true);
    try {
      final res = await OwnerAdminService.instance.pausarCuenta(
        targetId: widget.targetId,
        tipo: widget.tipo,
        pausar: pausar,
        motivo: notaInterna?.trim().isEmpty == true ? null : notaInterna?.trim(),
        motivoPublico: motivoPublico,
      );
      if (!mounted) return;
      _showResult(res, pausar ? 'Cuenta pausada' : 'Cuenta reactivada');
      if (res['ok'] == true) {
        await _cargar();
      }
    } catch (e) {
      if (!mounted) return;
      _showResult(
        {'ok': false, 'code': 'unexpected', 'error': e.toString()},
        '',
      );
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await _confirmar(
      '⚠️ Eliminar cuenta',
      'Esta acción es PERMANENTE. Se borrará la cuenta auth + todo el perfil + cascade '
      '(eventos, reviews, pagos, etc).\n\n¿Estás seguro?',
      'Sí, eliminar',
      destructiva: true,
    );
    if (!ok) return;
    // Doble confirmación
    final ok2 = await _confirmar(
      'Última confirmación',
      'Escribí "ELIMINAR" para confirmar.',
      'Eliminar',
      destructiva: true,
      requiereTexto: 'ELIMINAR',
    );
    if (!ok2) return;
    setState(() => _procesandoAccion = true);
    try {
      final res = await OwnerAdminService.instance.eliminarCuenta(widget.targetId);
      _showResult(res, 'Cuenta eliminada');
      if (res['ok'] == true && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  Future<bool> _confirmar(String titulo, String contenido, String btnLabel,
      {bool destructiva = false, String? requiereTexto}) async {
    final ctl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        final coincide = requiereTexto == null || ctl.text.trim() == requiereTexto;
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(contenido),
              if (requiereTexto != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: ctl,
                  onChanged: (_) => setSt(() {}),
                  decoration: InputDecoration(
                    hintText: requiereTexto,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: coincide ? () => Navigator.pop(ctx, true) : null,
              style: destructiva
                  ? FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626))
                  : null,
              child: Text(btnLabel),
            ),
          ],
        );
      }),
    );
    return res == true;
  }

  Future<Map<String, String>?> _pedirDatosPausa() async {
    final notaCtl = TextEditingController();
    String? motivoSeleccionado = motivosPausaPublicos.first.codigo;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Suspender cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'El usuario verá una pantalla bloqueada con el motivo público. '
                  'La nota interna solo la ves vos en Owner.',
                ),
                const SizedBox(height: 14),
                Text('Motivo para el usuario',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: motivoSeleccionado,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: motivosPausaPublicos
                      .map((m) => DropdownMenuItem(value: m.codigo, child: Text(m.etiqueta)))
                      .toList(),
                  onChanged: (v) => setSt(() => motivoSeleccionado = v),
                ),
                const SizedBox(height: 14),
                Text('Nota interna (privada)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                TextField(
                  controller: notaCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Memo para el equipo: detalle del caso, links, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: motivoSeleccionado == null
                  ? null
                  : () => Navigator.pop(ctx, {
                        'motivo_publico': motivoSeleccionado!,
                        'nota': notaCtl.text.trim(),
                      }),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
              child: const Text('Suspender'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResult(Map<String, dynamic> res, String successMsg) {
    if (!mounted) return;
    final ok = res['ok'] == true;
    final code = res['code']?.toString();
    final errMsg = res['error']?.toString();
    String fallo = 'Falló: ${errMsg ?? code ?? 'error desconocido'}';
    if (code == 'rate_limit_exceeded') {
      fallo = 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
    } else if (code == 'motivo_publico_requerido') {
      fallo = 'Elegí un motivo público para el usuario.';
    } else if (code == 'not_found') {
      fallo = 'No se encontró el perfil en la base. ¿El usuario completó registro?';
    } else if (code == 'no_autorizado') {
      fallo = 'Sin permisos de owner. Cerrá sesión y entrá con una cuenta owner activa.';
    } else if (code == 'rpc_not_found') {
      fallo = 'Falta la migración de pausa en Supabase (admin_pausar_cuenta).';
    } else if (code == 'tipo_invalido') {
      fallo = 'Tipo de cuenta inválido (esperado usuario o local).';
    }
    final messenger = ownerScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? successMsg : fallo),
      backgroundColor: ok ? const Color(0xFF15803D) : const Color(0xFFDC2626),
      duration: Duration(seconds: ok ? 3 : 5),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FC),
      appBar: AppBar(
        title: Text('@${widget.nombreInicial}'),
        actions: [
          IconButton(onPressed: _loading ? null : _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _data == null
                      ? const Center(child: Text('Sin datos'))
                      : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _bannerEstado(),
                              if (_estaPausada) const SizedBox(height: 14),
                              _accionesTop(),
                              const SizedBox(height: 20),
                              _statsGrid(),
                              const SizedBox(height: 20),
                              _infoTabla(),
                              const SizedBox(height: 20),
                              _seccionPublicaciones(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
          if (_procesandoAccion)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }

  // ─── Banner de estado pausada ───────────────────────────────────────────
  Widget _bannerEstado() {
    if (!_estaPausada) return const SizedBox.shrink();
    final notaInterna = _perfil['pausada_motivo']?.toString() ?? 'Sin nota';
    final motivoPublico = etiquetaMotivoPublico(
      _perfil['pausada_motivo_publico']?.toString(),
    );
    final pausadaEn = _perfil['pausada_en']?.toString();
    final fecha = pausadaEn != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(pausadaEn).toLocal())
        : '-';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle, color: Color(0xFFB91C1C), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuenta SUSPENDIDA',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF7F1D1D))),
                Text('Usuario ve: $motivoPublico',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B))),
                Text('Nota interna: $notaInterna · $fecha',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botones de acción arriba ───────────────────────────────────────────
  Widget _accionesTop() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _BotonAccion(
          icono: Icons.lock_reset,
          label: 'Ayuda con contraseña',
          color: const Color(0xFF3B82F6),
          onTap: _procesandoAccion ? null : _resetPassword,
        ),
        _BotonAccion(
          icono: _estaPausada ? Icons.play_circle : Icons.pause_circle,
          label: _estaPausada ? 'Reactivar cuenta' : 'Pausar cuenta',
          color: _estaPausada ? const Color(0xFF22C55E) : const Color(0xFFE67E22),
          cargando: _procesandoAccion,
          onTap: _procesandoAccion ? null : _togglePausar,
        ),
        _BotonAccion(
          icono: Icons.delete_forever,
          label: 'Eliminar cuenta',
          color: const Color(0xFFDC2626),
          onTap: _procesandoAccion ? null : _eliminar,
        ),
      ],
    );
  }

  // ─── Grid de stats ──────────────────────────────────────────────────────
  Widget _statsGrid() {
    final fmt = DateFormat('dd/MM/yyyy');
    final activoDesde = _esLocal
        ? _perfil['fecha_creacion']?.toString()
        : _perfil['creacion']?.toString();
    final activoStr = activoDesde != null
        ? fmt.format(DateTime.parse(activoDesde).toLocal())
        : '-';

    final items = <_StatItem>[
      _StatItem('Activo desde', activoStr, Icons.calendar_today, const Color(0xFF6366F1)),
      _StatItem('Email', _email, Icons.email, const Color(0xFF8B5CF6)),
    ];

    if (_esLocal) {
      items.addAll([
        _StatItem('Plan', (_perfil['plan_suscripcion']?.toString() ?? '-').toUpperCase(),
            Icons.workspace_premium, _planColor(_perfil['plan_suscripcion']?.toString())),
        _StatItem('Verificado', (_perfil['local_verificado'] == true) ? 'Sí' : 'No',
            Icons.verified, const Color(0xFF0EA5E9)),
        _StatItem('Eventos publicados', '${_stats['eventos_total'] ?? 0}',
            Icons.event, const Color(0xFF22C55E)),
        _StatItem('Eventos activos', '${_stats['eventos_activos'] ?? 0}',
            Icons.bolt, const Color(0xFFF59E0B)),
        _StatItem('Reviews recibidos', '${_stats['reviews_recibidas'] ?? 0}',
            Icons.rate_review, const Color(0xFFEC4899)),
        _StatItem('Promos', '${_stats['promos_total'] ?? 0}',
            Icons.local_offer, const Color(0xFFEF4444)),
        _StatItem('Staff activo', '${_stats['staff_activos'] ?? 0}',
            Icons.group, const Color(0xFF14B8A6)),
        _StatItem('Flyers IA usados', '${_stats['flyers_ia_usados'] ?? 0}',
            Icons.auto_awesome, const Color(0xFF8B5CF6)),
      ]);
    } else {
      items.addAll([
        _StatItem('Reviews escritas', '${_stats['reviews_escritas'] ?? 0}',
            Icons.rate_review, const Color(0xFFEC4899)),
        _StatItem('Tokens canjeados', '${_stats['tokens_canjeados'] ?? 0}',
            Icons.confirmation_number, const Color(0xFFF59E0B)),
        _StatItem('Promos canjeadas', '${_stats['tokens_promos_canjeados'] ?? 0}',
            Icons.local_offer, const Color(0xFFEF4444)),
        _StatItem('Grupos creados', '${_stats['grupos_creados'] ?? 0}',
            Icons.groups, const Color(0xFF22C55E)),
        _StatItem('Amigos', '${_stats['amigos'] ?? 0}',
            Icons.favorite, const Color(0xFFEC4899)),
      ]);
    }

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 800 ? 4 : c.maxWidth >= 520 ? 3 : 2;
      const gap = 10.0;
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items.map((it) => SizedBox(width: w, child: _statCard(it))).toList(),
      );
    });
  }

  Widget _statCard(_StatItem it) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: it.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(it.icono, color: it.color, size: 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              it.value,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            it.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _planColor(String? p) {
    switch (p?.toLowerCase()) {
      case 'standard':
        return const Color(0xFF6366F1);
      case 'plus':
        return const Color(0xFF0891B2);
      case 'premium':
        return const Color(0xFFF59E0B);
      case 'pionero':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ─── Tabla con toda la info del perfil ──────────────────────────────────
  Widget _infoTabla() {
    final rows = <MapEntry<String, String>>[];
    _perfil.forEach((k, v) {
      if (v == null) return;
      // Skip campos largos/internos
      if (k == 'pausada_por' || k == 'pausada_motivo' || k == 'pausada_motivo_publico' || k == 'pausada_en') return;
      if (v is List) {
        if (v.isEmpty) return;
        rows.add(MapEntry(k, v.join(', ')));
      } else {
        final s = v.toString();
        if (s.isEmpty) return;
        rows.add(MapEntry(k, s));
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF5A2EFF)),
                const SizedBox(width: 6),
                Text('Datos del perfil',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < rows.length; i++) ...[
            Container(
              color: i.isEven ? const Color(0xFFFAFAFC) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      rows[i].key,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      rows[i].value,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Sección publicaciones (dropdown expandible) ────────────────────────
  Widget _seccionPublicaciones() {
    if (_esLocal) {
      final eventos = (_data?['eventos'] as List?)?.cast<dynamic>() ?? [];
      final pagos = (_data?['pagos'] as List?)?.cast<dynamic>() ?? [];
      return Column(
        children: [
          _ExpansionLista(
            titulo: 'Eventos publicados',
            icon: Icons.event,
            color: const Color(0xFF6366F1),
            count: eventos.length,
            children: eventos.map<Widget>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _ItemEvento(item: m);
            }).toList(),
          ),
          const SizedBox(height: 10),
          _ExpansionLista(
            titulo: 'Historial de pagos',
            icon: Icons.payments,
            color: const Color(0xFF059669),
            count: pagos.length,
            children: pagos.map<Widget>((p) {
              final m = Map<String, dynamic>.from(p as Map);
              return _ItemPago(item: m);
            }).toList(),
          ),
        ],
      );
    } else {
      final reviews = (_data?['reviews_recientes'] as List?)?.cast<dynamic>() ?? [];
      final tokens = (_data?['tokens_recientes'] as List?)?.cast<dynamic>() ?? [];
      return Column(
        children: [
          _ExpansionLista(
            titulo: 'Últimas reviews escritas',
            icon: Icons.rate_review,
            color: const Color(0xFFEC4899),
            count: reviews.length,
            children: reviews.map<Widget>((r) {
              final m = Map<String, dynamic>.from(r as Map);
              return _ItemReview(item: m);
            }).toList(),
          ),
          const SizedBox(height: 10),
          _ExpansionLista(
            titulo: 'Últimos tokens',
            icon: Icons.confirmation_number,
            color: const Color(0xFFF59E0B),
            count: tokens.length,
            children: tokens.map<Widget>((t) {
              final m = Map<String, dynamic>.from(t as Map);
              return ListTile(
                dense: true,
                title: Text('Token ${m['estado'] ?? ''}'),
                subtitle: Text(_fmtDate(m['fecha']?.toString())),
              );
            }).toList(),
          ),
        ],
      );
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _StatItem {
  final String label;
  final String value;
  final IconData icono;
  final Color color;
  _StatItem(this.label, this.value, this.icono, this.color);
}

/// Card de elección en el bottom sheet de "Ayuda con contraseña".
class _OpcionResetCard extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final List<String> bullets;
  final bool recomendada;
  final VoidCallback onTap;

  const _OpcionResetCard({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.bullets,
    this.recomendada = false,
    required this.onTap,
  });

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
            border: Border.all(
              color: recomendada ? color : const Color(0xFFEAE6F5),
              width: recomendada ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (recomendada)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'RECOMENDADA',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    b,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool cargando;

  const _BotonAccion({
    required this.icono,
    required this.label,
    required this.color,
    required this.onTap,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: cargando
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.9)),
            )
          : Icon(icono, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

class _ExpansionLista extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Color color;
  final int count;
  final List<Widget> children;

  const _ExpansionLista({
    required this.titulo,
    required this.icon,
    required this.color,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDECF5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        title: Text(titulo,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ),
        children: count == 0
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin registros', style: TextStyle(color: Colors.black45)),
                )
              ]
            : children,
      ),
    );
  }
}

class _ItemEvento extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemEvento({required this.item});

  @override
  Widget build(BuildContext context) {
    final titulo = item['titulo']?.toString() ?? '-';
    final jerarquia = item['jerarquia']?.toString() ?? 'normal';
    final estado = item['estado_publicacion']?.toString() ?? '-';
    final borrado = item['borrado'] == true;
    final fechaIni = item['fecha_inicio']?.toString();
    final fechaStr = fechaIni != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaIni).toLocal())
        : '-';

    final (jColor, jLabel) = switch (jerarquia) {
      'top_ultra' => (const Color(0xFFEF4444), 'TOP ULTRA'),
      'top' => (const Color(0xFFF59E0B), 'TOP'),
      'recomendado' => (const Color(0xFF8B5CF6), 'RECO'),
      _ => (const Color(0xFF6B7280), 'NORMAL'),
    };

    return ListTile(
      dense: true,
      title: Text(
        titulo,
        style: TextStyle(
          decoration: borrado ? TextDecoration.lineThrough : null,
          color: borrado ? Colors.grey : null,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text('$fechaStr · ${item['visitas'] ?? 0} visitas · ${item['canjeos'] ?? 0} canjes'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: jColor,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(jLabel,
                style: const TextStyle(
                    color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: borrado
                  ? Colors.grey.shade300
                  : estado == 'publicado'
                      ? const Color(0xFF22C55E)
                      : Colors.grey,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(borrado ? 'BORRADO' : estado.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _ItemPago extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemPago({required this.item});

  @override
  Widget build(BuildContext context) {
    final estado = item['estado']?.toString() ?? '-';
    final plan = item['plan_solicitado']?.toString() ?? '-';
    final monto = item['monto_usd']?.toString() ?? '-';
    final fecha = item['creado_en']?.toString();
    final fechaStr = fecha != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha).toLocal())
        : '-';
    return ListTile(
      dense: true,
      title: Text('USD $monto · plan $plan',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$fechaStr · ${item['tipo_solicitud'] ?? ''}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: estado == 'aplicado'
              ? const Color(0xFF22C55E)
              : estado == 'rechazado'
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE67E22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(estado.toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ItemReview extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemReview({required this.item});

  @override
  Widget build(BuildContext context) {
    final stars = (item['estrellas'] as num?)?.toInt() ?? 0;
    final coment = item['comentario']?.toString() ?? '';
    final localUsername = item['local_username']?.toString() ?? '?';
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('★ $stars',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      ),
      title: Text('@$localUsername',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(coment, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
