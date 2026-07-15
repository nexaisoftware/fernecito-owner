import 'package:flutter/material.dart';

import '../models/push_filtros.dart';

/// Íconos de app para push segmentada (verde = usuarios, violeta = locales).
class PushAppAssets {
  PushAppAssets._();

  static const usuarios = 'assets/images/icono_usuarios.png';
  static const locales = 'assets/images/icono_locales.png';
}

/// Muestra el logo de la app destino según [target]: usuarios, locales o ambos.
class PushAppIcon extends StatelessWidget {
  const PushAppIcon({
    super.key,
    required this.target,
    this.size = 38,
    this.borderRadius = 10,
    this.overlap = 10,
  });

  final String target;
  final double size;
  final double borderRadius;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (target == 'ambos') {
      return SizedBox(
        width: size + overlap,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              child: _single(PushAppAssets.usuarios),
            ),
            Positioned(
              left: overlap,
              child: _single(PushAppAssets.locales),
            ),
          ],
        ),
      );
    }

    return _single(
      target == 'locales' ? PushAppAssets.locales : PushAppAssets.usuarios,
    );
  }

  Widget _single(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade300,
          child: const Icon(Icons.apps_rounded, size: 20),
        ),
      ),
    );
  }
}

/// Texto de confirmación según el segmento y filtros elegidos.
String pushTargetConfirmacion(String target, {PushFiltros? filtros}) {
  final f = filtros ?? const PushFiltros();
  if (!f.activo) {
    return switch (target) {
      'locales' =>
        '¿Seguro querés mandar esta notificación a todos los locales?',
      'ambos' =>
        '¿Seguro querés mandar esta notificación a todos los usuarios y locales?',
      _ => '¿Seguro querés mandar esta notificación a todos los usuarios?',
    };
  }

  return '¿Seguro querés mandar esta notificación segmentada?\n\n'
      '${f.resumenDetalle(target: target)}';
}

String pushTargetAppLabel(String target) => switch (target) {
      'locales' => 'Fernecito Locales',
      'ambos' => 'Fernecito · usuarios y locales',
      _ => 'Fernecito',
    };
