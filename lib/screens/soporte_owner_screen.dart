import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/owner_theme.dart';
import '../services/owner_soporte_service.dart';

/// Fila unificada para mostrar locales y usuarios en una sola lista.
class _FilaSoporte {
  final bool abierta;
  final DateTime? fecha;
  final SoporteTicket? local;
  final SoporteTicketUsuario? usuario;
  _FilaSoporte({
    required this.abierta,
    required this.fecha,
    this.local,
    this.usuario,
  });
}

/// Dashboard de soporte para el owner.
/// Lista los tickets abiertos del sistema (1 por local), permite copiar la
/// respuesta-template con el código anti-estafa, y cerrar la consulta.
class SoporteOwnerScreen extends StatefulWidget {
  const SoporteOwnerScreen({super.key});

  @override
  State<SoporteOwnerScreen> createState() => _SoporteOwnerScreenState();
}

class _SoporteOwnerScreenState extends State<SoporteOwnerScreen> {
  List<SoporteTicket> _tickets = [];
  List<SoporteTicketUsuario> _ticketsUsuarios = [];
  bool _loading = true;
  bool _soloAbiertos = true;
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
      final locales = OwnerSoporteService.instance.listar(
        soloAbiertos: _soloAbiertos,
      );
      final usuarios = OwnerSoporteService.instance.listarUsuarios(
        soloAbiertos: _soloAbiertos,
      );
      final l = await locales;
      final u = await usuarios;
      if (!mounted) return;
      setState(() {
        _tickets = l;
        _ticketsUsuarios = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los tickets: $e';
        _loading = false;
      });
    }
  }

  Future<void> _cerrarUsuario(SoporteTicketUsuario t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar consulta?'),
        content: Text(
          'Vas a marcar como terminada la consulta de @${t.username ?? '?'}.'
          '\n\nEl código ${t.codigoAntiestafa} dejará de mostrarse en la app del usuario.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await OwnerSoporteService.instance.cerrarUsuario(t.idUsuario);
      if (!mounted) return;
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta cerrada')),
        );
        _cargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar: ${res['code'] ?? 'error'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _copiarCodigoUsuario(SoporteTicketUsuario t) async {
    await Clipboard.setData(ClipboardData(text: t.codigoAntiestafa));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código ${t.codigoAntiestafa} copiado')),
    );
  }

  Future<void> _copiarEmailUsuario(SoporteTicketUsuario t) async {
    await Clipboard.setData(ClipboardData(text: t.email ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email copiado')),
    );
  }

  Future<void> _cerrar(SoporteTicket t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar consulta?'),
        content: Text(
          'Vas a marcar como terminada la consulta de @${t.localUsername ?? '?'}.'
          '\n\nEl código ${t.codigoAntiestafa} ya no será válido — si el local te '
          'vuelve a escribir va a generar uno nuevo desde su app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await OwnerSoporteService.instance.cerrar(t.idLocal);
      if (!mounted) return;
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta cerrada')),
        );
        _cargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar: ${res['code'] ?? 'error'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _templateRespuesta(SoporteTicket t) {
    final via = t.viaContacto == 'email' ? 'email' : 'WhatsApp';
    return '¡Hola @${t.localUsername ?? ''}! 👋\n\n'
        'Soy del soporte oficial de Fernecito. '
        'Para tu seguridad, tu código anti-estafa es: ${t.codigoAntiestafa}\n\n'
        'Verificalo en la app (sección Ayuda y soporte) para confirmar que '
        'estás hablando con el equipo oficial y NO con alguien que se hace pasar.\n\n'
        'Una vez verificado, contame cómo puedo ayudarte por $via.\n\n'
        '— Equipo Fernecito 🥃';
  }

  Future<void> _copiarRespuesta(SoporteTicket t) async {
    await Clipboard.setData(ClipboardData(text: _templateRespuesta(t)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Respuesta copiada — pegala en WhatsApp/email'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copiarCodigo(SoporteTicket t) async {
    await Clipboard.setData(ClipboardData(text: t.codigoAntiestafa));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código ${t.codigoAntiestafa} copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerTheme.fondo,
      child: RefreshIndicator(
        onRefresh: _cargar,
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final abiertas = _tickets.where((t) => t.esAbierta).length +
        _ticketsUsuarios.where((t) => t.esAbierta).length;
    final total = _tickets.length + _ticketsUsuarios.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent, color: Color(0xFF15803D), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soporte',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(
                  _loading
                      ? 'Cargando…'
                      : '$abiertas abierta${abiertas == 1 ? '' : 's'} · $total total',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Toggle abiertas / todas
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Abiertas')),
              ButtonSegment(value: false, label: Text('Todas')),
            ],
            selected: {_soloAbiertos},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              setState(() => _soloAbiertos = s.first);
              _cargar();
            },
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    // Locales + usuarios en UNA sola lista, abiertas primero, más recientes arriba.
    final filas = <_FilaSoporte>[
      for (final t in _tickets)
        _FilaSoporte(abierta: t.esAbierta, fecha: t.ultimaOperacion, local: t),
      for (final t in _ticketsUsuarios)
        _FilaSoporte(abierta: t.esAbierta, fecha: t.ultimaOperacion, usuario: t),
    ];
    if (filas.isEmpty) {
      return _vacio(_soloAbiertos
          ? 'No hay consultas abiertas'
          : 'Sin tickets de soporte todavía');
    }
    filas.sort((a, b) {
      if (a.abierta != b.abierta) return a.abierta ? -1 : 1;
      final fa = a.fecha ?? DateTime(2000);
      final fb = b.fecha ?? DateTime(2000);
      return fb.compareTo(fa);
    });
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final f = filas[i];
        if (f.usuario != null) {
          final t = f.usuario!;
          return _UsuarioTicketCard(
            ticket: t,
            onCopiarCodigo: () => _copiarCodigoUsuario(t),
            onCopiarEmail: () => _copiarEmailUsuario(t),
            onCerrar: t.esAbierta ? () => _cerrarUsuario(t) : null,
          );
        }
        final t = f.local!;
        return _TicketCard(
          ticket: t,
          onCopiarRespuesta: () => _copiarRespuesta(t),
          onCopiarCodigo: () => _copiarCodigo(t),
          onCerrar: t.esAbierta ? () => _cerrar(t) : null,
        );
      },
    );
  }

  Widget _vacio(String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card de un ticket
// ═══════════════════════════════════════════════════════════════════════════

class _TicketCard extends StatelessWidget {
  final SoporteTicket ticket;
  final VoidCallback onCopiarRespuesta;
  final VoidCallback onCopiarCodigo;
  final VoidCallback? onCerrar;

  const _TicketCard({
    required this.ticket,
    required this.onCopiarRespuesta,
    required this.onCopiarCodigo,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final fecha = ticket.ultimaOperacion != null
        ? fmt.format(ticket.ultimaOperacion!.toLocal())
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ticket.esAbierta
              ? const Color(0xFF22C55E).withValues(alpha: 0.35)
              : const Color(0xFFEAE6F5),
          width: ticket.esAbierta ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + username + chips
            Row(
              children: [
                _Avatar(url: ticket.fotoPerfilUrl, fallback: ticket.localUsername ?? '?'),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '@${ticket.localUsername ?? '?'}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (ticket.localVerificado) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Color(0xFF0EA5E9)),
                          ],
                        ],
                      ),
                      if ((ticket.nombreLocal ?? '').isNotEmpty)
                        Text(
                          ticket.nombreLocal!,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips: estado + via + plan
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(
                  label: ticket.esAbierta ? 'Abierta' : 'Cerrada',
                  color: ticket.esAbierta
                      ? const Color(0xFF22C55E)
                      : Colors.grey.shade600,
                  filled: true,
                ),
                _Chip(
                  label: ticket.viaContacto == 'whatsapp'
                      ? 'WhatsApp'
                      : ticket.viaContacto == 'email'
                          ? 'Email'
                          : 'Sin vía',
                  color: ticket.viaContacto == 'whatsapp'
                      ? const Color(0xFF22C55E)
                      : ticket.viaContacto == 'email'
                          ? const Color(0xFF3B82F6)
                          : Colors.grey,
                  icon: ticket.viaContacto == 'whatsapp'
                      ? Icons.chat
                      : ticket.viaContacto == 'email'
                          ? Icons.email
                          : Icons.help_outline,
                ),
                if ((ticket.planSuscripcion ?? '').isNotEmpty)
                  _Chip(
                    label: (ticket.planSuscripcion ?? '').toUpperCase(),
                    color: const Color(0xFF5A2EFF),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Bloque del código antiestafa
            InkWell(
              onTap: onCopiarCodigo,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código anti-estafa',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            )),
                        Text(
                          ticket.codigoAntiestafa,
                          style: GoogleFonts.robotoMono(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF78350F),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.copy, size: 18, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  fecha,
                  style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Acciones
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCopiarRespuesta,
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Copiar respuesta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5A2EFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (onCerrar != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onCerrar,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Cerrar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      side: const BorderSide(color: Color(0xFF15803D)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String fallback;
  const _Avatar({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isNotEmpty ? fallback[0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFEDE9FE),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEDE9FE),
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: const Color(0xFF5A2EFF),
          fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card de un ticket de USUARIO (email + código + mensaje; el owner cierra)
// ═══════════════════════════════════════════════════════════════════════════

class _UsuarioTicketCard extends StatelessWidget {
  final SoporteTicketUsuario ticket;
  final VoidCallback onCopiarCodigo;
  final VoidCallback onCopiarEmail;
  final VoidCallback? onCerrar;

  const _UsuarioTicketCard({
    required this.ticket,
    required this.onCopiarCodigo,
    required this.onCopiarEmail,
    this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final abierta = ticket.esAbierta;
    final fecha = ticket.ultimaOperacion;
    final fechaStr =
        fecha != null ? DateFormat('dd/MM HH:mm').format(fecha.toLocal()) : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: abierta ? const Color(0xFF22C55E) : OwnerTheme.borde,
          width: abierta ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: usuario + estado
          Row(
            children: [
              const Icon(Icons.person_rounded, color: OwnerTheme.violetaMarca),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.username != null && ticket.username!.isNotEmpty
                          ? '@${ticket.username}'
                          : (ticket.nombre ?? 'Usuario'),
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Usuario · ${abierta ? 'Abierta' : 'Cerrada'}${fechaStr.isNotEmpty ? ' · $fechaStr' : ''}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: OwnerTheme.violetaMarca),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (abierta
                          ? const Color(0xFF22C55E)
                          : Colors.grey)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  abierta ? 'ABIERTA' : 'CERRADA',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: abierta
                        ? const Color(0xFF15803D)
                        : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Email (para contactar) + código (para verificar)
          _filaDato(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            valor: ticket.email ?? '—',
            onCopiar: onCopiarEmail,
          ),
          const SizedBox(height: 8),
          _filaDato(
            icon: Icons.verified_user_outlined,
            label: 'Código anti-estafa',
            valor: ticket.codigoAntiestafa,
            destacar: true,
            onCopiar: onCopiarCodigo,
          ),
          if ((ticket.telefono ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _filaDato(
              icon: FontAwesomeIcons.whatsapp,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp (consultas con chat)',
              valor: ticket.telefono!,
              onCopiar: () =>
                  Clipboard.setData(ClipboardData(text: ticket.telefono!)),
              onAbrir: () =>
                  _abrirWhatsApp(ticket.telefono!, ticket.codigoAntiestafa),
            ),
          ],
          const SizedBox(height: 12),
          // Mensaje
          Text('Consulta',
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (ticket.mensaje ?? '').isEmpty ? '—' : ticket.mensaje!,
              style: GoogleFonts.inter(fontSize: 13, height: 1.35),
            ),
          ),
          if (onCerrar != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCerrar,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Cerrar consulta'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filaDato({
    required IconData icon,
    required String label,
    required String valor,
    bool destacar = false,
    Color? iconColor,
    VoidCallback? onCopiar,
    VoidCallback? onAbrir,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: iconColor ??
                (destacar ? OwnerTheme.violetaMarca : Colors.black45)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45)),
              Text(
                valor,
                style: GoogleFonts.inter(
                  fontSize: destacar ? 16 : 13.5,
                  fontWeight: destacar ? FontWeight.w900 : FontWeight.w700,
                  color: destacar
                      ? OwnerTheme.violetaMarca
                      : Colors.black87,
                  letterSpacing: destacar ? 1 : 0,
                ),
              ),
            ],
          ),
        ),
        if (onAbrir != null)
          IconButton(
            onPressed: onAbrir,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF25D366),
            tooltip: 'Abrir chat de WhatsApp',
          ),
        if (onCopiar != null)
          IconButton(
            onPressed: onCopiar,
            icon: const Icon(Icons.copy_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            color: Colors.black45,
          ),
      ],
    );
  }

  Future<void> _abrirWhatsApp(String numero, String codigo) async {
    final limpio = numero.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpio.isEmpty) return;
    final msg = '¡Hola! 👋 Soy del soporte oficial de Fernecito. '
        'Para tu seguridad, tu código anti-estafa es: $codigo. '
        'Verificalo en la app (Ayuda y soporte) para confirmar que somos nosotros.';
    final uri =
        Uri.parse('https://wa.me/$limpio?text=${Uri.encodeComponent(msg)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
