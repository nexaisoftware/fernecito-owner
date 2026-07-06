import 'package:flutter/material.dart';

import '../core/owner_theme.dart';
import '../core/pagos_subseccion.dart';
import '../services/owner_service.dart';
import '../widgets/pagos_segment_switch.dart';
import 'pagos_screen.dart';

/// Módulo unificado de pagos con subsecciones internas.
class PagosOwnerScreen extends StatefulWidget {
  const PagosOwnerScreen({super.key});

  @override
  State<PagosOwnerScreen> createState() => _PagosOwnerScreenState();
}

class _PagosOwnerScreenState extends State<PagosOwnerScreen> {
  PagosSubseccion _subseccion = PagosSubseccion.pendientes;
  bool _cronLoading = false;

  Future<void> _ejecutarCron() async {
    if (_cronLoading) return;
    setState(() => _cronLoading = true);
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final r = await OwnerService.instance.ejecutarCronManual();
      if (!mounted) return;
      final ok = r['ok'] == true;
      final renovados = r['renovados'];
      final vencidos = r['vencidos'];
      final recuperados = r['recuperados'];
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Cron OK · renovados: ${renovados ?? 0}, vencidos: ${vencidos ?? 0}, recuperados: ${recuperados ?? 0}'
                : 'Cron falló: ${r['code'] ?? r['error'] ?? 'error'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _cronLoading = false);
    }
  }

  Widget _refrescarSistemaBtn(bool compact) {
    return Material(
      color: OwnerTheme.violetaMarca.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _cronLoading ? null : _ejecutarCron,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 7 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_cronLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OwnerTheme.violetaMarca,
                  ),
                )
              else
                Icon(Icons.sync_rounded, size: compact ? 15 : 16, color: OwnerTheme.violetaMarca),
              SizedBox(width: compact ? 5 : 6),
              Text(
                'Refrescar sistema',
                style: OwnerTheme.baloo(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  color: OwnerTheme.violetaMarca,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPad = isCompact ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Pagos',
                      style: OwnerTheme.baloo(
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w900,
                        color: OwnerTheme.texto,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _refrescarSistemaBtn(isCompact),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _subseccion.descripcion,
                style: OwnerTheme.baloo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OwnerTheme.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              PagosSegmentSwitch(
                selected: _subseccion,
                onChanged: (s) => setState(() => _subseccion = s),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PagosScreen(
            key: ValueKey(_subseccion),
            subseccion: _subseccion,
          ),
        ),
      ],
    );
  }
}
