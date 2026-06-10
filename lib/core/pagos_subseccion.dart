import 'package:flutter/material.dart';

/// Subsecciones internas del módulo Pagos (navbar principal).
enum PagosSubseccion {
  pendientes(
    label: 'Pendientes',
    shortLabel: 'Pend.',
    descripcion: 'Solicitudes para revisar',
    estados: ['pendiente'],
    soloLectura: false,
    icon: Icons.hourglass_top_rounded,
  ),
  aprobados(
    label: 'Aprobados',
    shortLabel: 'Aprob.',
    descripcion: 'Renovaciones y downgrades agendados',
    estados: ['aprobado_pendiente'],
    soloLectura: false,
    icon: Icons.check_circle_outline_rounded,
  ),
  historial(
    label: 'Historial',
    shortLabel: 'Hist.',
    descripcion: 'Aplicados y rechazados',
    estados: ['aplicado', 'rechazado'],
    soloLectura: true,
    icon: Icons.history_rounded,
  );

  const PagosSubseccion({
    required this.label,
    required this.shortLabel,
    required this.descripcion,
    required this.estados,
    required this.soloLectura,
    required this.icon,
  });

  final String label;
  final String shortLabel;
  final String descripcion;
  final List<String> estados;
  final bool soloLectura;
  final IconData icon;
}
