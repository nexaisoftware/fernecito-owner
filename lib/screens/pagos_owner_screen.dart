import 'package:flutter/material.dart';

import '../core/owner_layout.dart';
import '../core/owner_theme.dart';
import '../core/pagos_subseccion.dart';
import '../widgets/owner_subpage_scaffold.dart';
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

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPad = isCompact ? 16.0 : 20.0;

    return OwnerSubpageScaffold(
      constrainBody: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerLayout.constrain(
            context: context,
            padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagos',
                  style: OwnerTheme.baloo(
                    fontSize: isCompact ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: OwnerTheme.texto,
                  ),
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
      ),
    );
  }
}
