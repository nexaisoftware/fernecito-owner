import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/owner_theme.dart';
import '../services/owner_soporte_service.dart';

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
      final list = await OwnerSoporteService.instance.listar(
        soloAbiertos: _soloAbiertos,
      );
      if (!mounted) return;
      setState(() {
        _tickets = list;
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
    final abiertas = _tickets.where((t) => t.esAbierta).length;
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
                      : '$abiertas abierta${abiertas == 1 ? '' : 's'} · ${_tickets.length} total',
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
    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _soloAbiertos
                    ? 'No hay consultas abiertas'
                    : 'Sin tickets de soporte todavía',
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _TicketCard(
        ticket: _tickets[i],
        onCopiarRespuesta: () => _copiarRespuesta(_tickets[i]),
        onCopiarCodigo: () => _copiarCodigo(_tickets[i]),
        onCerrar: _tickets[i].esAbierta ? () => _cerrar(_tickets[i]) : null,
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
