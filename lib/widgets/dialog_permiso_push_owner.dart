library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/owner_theme.dart';
import '../core/servicio_push_owner.dart';

class DialogPermisoPushOwner {
  DialogPermisoPushOwner._();

  static bool _mostrando = false;
  static bool _mostradoEstaSesion = false;

  static Future<void> mostrarSiCorresponde(BuildContext context) async {
    if (_mostrando || _mostradoEstaSesion) return;
    if (!ServicioPushOwner.instancia.soportado) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    if (await ServicioPushOwner.instancia.tienePermiso()) return;

    _mostradoEstaSesion = true;
    if (!context.mounted) return;

    _mostrando = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded,
                color: OwnerTheme.violetaMarca),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alertas urgentes',
                style: OwnerTheme.baloo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Activá notificaciones para enterarte al instante de pagos nuevos, '
          'reportes de moderación y tickets de soporte que requieren atención.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: OwnerTheme.textoSecundario,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ServicioPushOwner.instancia.registrarParaOwner();
            },
            icon: const Icon(Icons.notifications_rounded),
            label: const Text('Activar'),
          ),
        ],
      ),
    );
    _mostrando = false;
  }
}
