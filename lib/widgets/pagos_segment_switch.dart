import 'package:flutter/material.dart';

import '../core/owner_theme.dart';
import '../core/pagos_subseccion.dart';

/// Selector de subsección de pagos (una activa a la vez).
class PagosSegmentSwitch extends StatelessWidget {
  final PagosSubseccion selected;
  final ValueChanged<PagosSubseccion> onChanged;

  const PagosSegmentSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SegmentedButton<PagosSubseccion>(
          segments: PagosSubseccion.values.map((s) {
            return ButtonSegment<PagosSubseccion>(
              value: s,
              icon: Icon(s.icon, size: compact ? 18 : 20),
              label: compact
                  ? null
                  : Text(
                      s.label,
                      style: OwnerTheme.baloo(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
              tooltip: compact ? s.label : null,
            );
          }).toList(),
          selected: {selected},
          onSelectionChanged: (next) {
            if (next.isNotEmpty) onChanged(next.first);
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: compact ? 8 : 14,
                vertical: compact ? 10 : 12,
              ),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: OwnerTheme.borde),
            ),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return OwnerTheme.violetaMarca;
              }
              return OwnerTheme.textoSecundario;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return OwnerTheme.violetaMarca.withValues(alpha: 0.1);
              }
              return OwnerTheme.superficie;
            }),
          ),
        );
      },
    );
  }
}
