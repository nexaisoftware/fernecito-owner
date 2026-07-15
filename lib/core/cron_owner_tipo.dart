import 'package:flutter/material.dart';

/// Tipos de cron que el owner puede forzar manualmente desde el dashboard.
enum CronOwnerTipo {
  todos(
    'todos',
    'Todos los crons',
    'Suscripciones, notificaciones, eventos y pioneros',
    Icons.all_inclusive_rounded,
  ),
  notificaciones(
    'notificaciones',
    'Notificaciones',
    'Recordatorios, vencimientos y push pendientes en cola',
    Icons.notifications_active_rounded,
  ),
  suscripciones(
    'suscripciones',
    'Suscripciones',
    'Vence y renueva planes de locales al instante',
    Icons.workspace_premium_rounded,
  ),
  eventos(
    'eventos',
    'Eventos',
    'Mantenimiento de cartelera, tokens y jerarquías',
    Icons.event_available_rounded,
  ),
  pioneros(
    'pioneros',
    'Pioneros',
    'Créditos mensuales y cierre de beneficios',
    Icons.auto_awesome_rounded,
  );

  const CronOwnerTipo(this.id, this.titulo, this.descripcion, this.icono);

  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;
}

String cronOwnerResumen(Map<String, dynamic> res) {
  if (res['ok'] != true) {
    return 'Falló: ${res['error'] ?? res['detail'] ?? 'error'}';
  }
  final errores = res['errores'];
  if (errores is List && errores.isNotEmpty) {
    return 'Parcial (${res['tipo']}): ${errores.join(' · ')}';
  }
  final tipo = res['tipo']?.toString() ?? 'cron';
  final resultado = res['resultado'];
  if (resultado is Map) {
    final s = resultado['suscripciones'];
    if (s is Map && (s['renovados'] != null || s['vencidos'] != null)) {
      return '$tipo OK · renovados: ${s['renovados'] ?? 0}, vencidos: ${s['vencidos'] ?? 0}';
    }
    final n = resultado['notificaciones'];
    if (n is Map) {
      final push = n['push_pendientes'];
      if (push is Map && push['enviados'] != null) {
        return '$tipo OK · push enviados: ${push['enviados']}';
      }
    }
  }
  return 'Cron $tipo ejecutado correctamente';
}
