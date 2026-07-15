import 'package:flutter/material.dart';

/// Tabs principales del panel Owner (navbar / rail).
enum OwnerNavModulo {
  dashboard(Icons.dashboard_rounded, 'Inicio'),
  metricas(Icons.bar_chart_rounded, 'Métricas'),
  soporte(Icons.support_agent_rounded, 'Soporte'),
  moderacion(Icons.report_problem_rounded, 'Moderación');

  const OwnerNavModulo(this.icon, this.label);

  final IconData icon;
  final String label;
}
