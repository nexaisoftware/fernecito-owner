import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/cron_owner_tipo.dart';
import '../core/owner_theme.dart';
import '../services/owner_service.dart';
import 'owner_desktop_refresh.dart';

/// Selector de cron compacto (plegable) en el dashboard.
class CronOwnerPanel extends StatefulWidget {
  const CronOwnerPanel({super.key, this.onCompletado});

  final VoidCallback? onCompletado;

  @override
  State<CronOwnerPanel> createState() => _CronOwnerPanelState();
}

class _CronOwnerPanelState extends State<CronOwnerPanel> {
  CronOwnerTipo _tipo = CronOwnerTipo.notificaciones;
  bool _ejecutando = false;

  Future<void> _ejecutar() async {
    if (_ejecutando) return;
    setState(() => _ejecutando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await OwnerService.instance.ejecutarCronOwner(tipo: _tipo);
      if (!mounted) return;
      final ok = res['ok'] == true;
      messenger.showSnackBar(
        SnackBar(
          content: Text(cronOwnerResumen(res)),
          backgroundColor: ok ? OwnerTheme.violetaMarca : Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
      if (ok) widget.onCompletado?.call();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al ejecutar cron: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _ejecutando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwnerTheme.borde),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          iconColor: OwnerTheme.violetaMarca,
          collapsedIconColor: OwnerTheme.textoSecundario,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: OwnerTheme.violetaMarca.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sync_rounded,
              size: 18,
              color: OwnerTheme.violetaMarca,
            ),
          ),
          title: Text(
            'Forzar crons del sistema',
            style: OwnerTheme.baloo(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'Seleccionado: ${_tipo.titulo}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: OwnerTheme.textoSecundario,
            ),
          ),
          children: [
            ...CronOwnerTipo.values.map((t) {
              final sel = _tipo == t;
              return InkWell(
                onTap: _ejecutando ? null : () => setState(() => _tipo = t),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: sel
                            ? OwnerTheme.violetaMarca
                            : OwnerTheme.textoSecundario,
                      ),
                      const SizedBox(width: 8),
                      Icon(t.icono, size: 16, color: OwnerTheme.violetaMarca),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Text(
              _tipo.descripcion,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: OwnerTheme.textoSecundario,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            OwnerAdaptiveButton(
              onPressed: _ejecutar,
              loading: _ejecutando,
              icon: const Icon(Icons.play_arrow_rounded),
              label: _ejecutando ? 'Ejecutando…' : 'Ejecutar cron',
              maxWidth: 220,
            ),
          ],
        ),
      ),
    );
  }
}
