import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/owner_metrics_service.dart';

void main() {
  // JSON completo que simula la respuesta de la RPC metricas_owner_completas
  const fullJson = <String, dynamic>{
    'cuentas': {'total': 120, 'usuarios': 90, 'locales': 30},
    'verificacion': {'verificados': 25, 'no_verificados': 5},
    'planes': {
      'sin_verificar': 5,
      'gratis': 15,
      'standard': 6,
      'plus': 2,
      'premium': 1,
      'pionero': 1,
      'pagos': 10,
    },
    'eventos': {
      'total': 200,
      'publicados': 150,
      'activos': 40,
      'jerarquias': {
        'top_ultra': 3,
        'top': 12,
        'recomendado': 20,
        'gratis': 60,
        'normal': 55,
      },
      'visitas': 1500,
      'reservas': 300,
      'tokens_emitidos': 800,
      'tokens_canjeados': 600,
    },
    'flyers_ia': {
      'total': 50,
      'entregados': 45,
      'creditos_usados': 50,
      'este_mes': 10,
      'retries': 3,
      'tasa_entrega_pct': 90.0,
    },
    'promociones': {'total': 80, 'activas': 30, 'cupos_usados': 120},
    'reviews': {'total': 200, 'promedio_estrellas': 4.3},
    'pagos': {
      'pendientes': 5,
      'aplicados': 100,
      'rechazados': 2,
      'ingresos_usd_total': 1250.50,
      'ingresos_ars_total': 850000.0,
    },
    'generado_en': '2026-06-02T10:00:00.000Z',
  };

  group('OwnerMetricsSnapshot.fromJson — cuentas y planes', () {
    test('parsea cuentas correctamente', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.cuentasTotal, 120);
      expect(s.usuarios, 90);
      expect(s.locales, 30);
    });

    test('parsea desglose de planes', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.planSinVerificar, 5);
      expect(s.planGratis, 15);
      expect(s.planStandard, 6);
      expect(s.planPlus, 2);
      expect(s.planPremium, 1);
      expect(s.planPionero, 1);
      expect(s.localesPagos, 10);
    });

    test('parsea verificados / no verificados', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.verificados, 25);
      expect(s.noVerificados, 5);
    });
  });

  group('OwnerMetricsSnapshot.fromJson — eventos y jerarquías', () {
    test('parsea totales de eventos', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.eventosTotal, 200);
      expect(s.eventosPublicados, 150);
      expect(s.eventosActivos, 40);
    });

    test('parsea jerarquías individuales', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.jerarqUltra, 3);
      expect(s.jerarqTop, 12);
      expect(s.jerarqReco, 20);
      expect(s.jerarqGratis, 60);
      expect(s.jerarqNormal, 55);
    });

    test('parsea tokens emitidos y canjeados', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.tokensEmitidos, 800);
      expect(s.tokensCanjeados, 600);
    });
  });

  group('OwnerMetricsSnapshot.fromJson — pagos e ingresos', () {
    test('parsea estados de pagos', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.pagosPendientes, 5);
      expect(s.pagosAplicados, 100);
      expect(s.pagosRechazados, 2);
    });

    test('parsea ingresos en USD y ARS como double', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.ingresosUsd, closeTo(1250.50, 0.01));
      expect(s.ingresosArs, closeTo(850000.0, 0.01));
    });

    test('parsea reviewsPromedio como double', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.reviewsTotal, 200);
      expect(s.reviewsPromedio, closeTo(4.3, 0.01));
    });
  });

  group('OwnerMetricsSnapshot.fromJson — timestamp', () {
    test('parsea generadoEn como DateTime', () {
      final s = OwnerMetricsSnapshot.fromJson(fullJson);
      expect(s.generadoEn, isNotNull);
      expect(s.generadoEn!.year, 2026);
      expect(s.generadoEn!.month, 6);
      expect(s.generadoEn!.day, 2);
    });

    test('generadoEn null si campo ausente', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('generado_en');
      expect(OwnerMetricsSnapshot.fromJson(json).generadoEn, isNull);
    });
  });

  group('OwnerMetricsSnapshot.fromJson — robustez', () {
    test('planSinVerificar usa verificacion.no_verificados como fallback', () {
      // La RPC puede enviar el campo en planes o en verificacion según versión
      final json = Map<String, dynamic>.from(fullJson);
      final planes = Map<String, dynamic>.from(json['planes'] as Map)
        ..remove('sin_verificar');
      json['planes'] = planes;
      final s = OwnerMetricsSnapshot.fromJson(json);
      expect(s.planSinVerificar, 5); // viene de verificacion.no_verificados
    });

    test('devuelve 0 para campos numéricos ausentes o nulos', () {
      const emptyJson = <String, dynamic>{
        'cuentas': {'total': null, 'usuarios': null, 'locales': null},
        'verificacion': {'verificados': null, 'no_verificados': null},
        'planes': <String, dynamic>{},
        'eventos': {
          'total': null,
          'publicados': null,
          'activos': null,
          'jerarquias': <String, dynamic>{},
        },
        'flyers_ia': <String, dynamic>{},
        'promociones': <String, dynamic>{},
        'reviews': <String, dynamic>{},
        'pagos': <String, dynamic>{},
      };
      final s = OwnerMetricsSnapshot.fromJson(emptyJson);
      expect(s.cuentasTotal, 0);
      expect(s.flyersTasaEntrega, 0.0);
      expect(s.ingresosUsd, 0.0);
      expect(s.reviewsPromedio, 0.0);
    });

    test('acepta valores numéricos enviados como String', () {
      final json = Map<String, dynamic>.from(fullJson);
      // Reemplazamos el mapa anidado completo (el original es const, no mutable)
      json['cuentas'] = <String, dynamic>{'total': '99', 'usuarios': 90, 'locales': 30};
      expect(OwnerMetricsSnapshot.fromJson(json).cuentasTotal, 99);
    });
  });

  group('OwnerMetricsSnapshot.vacio', () {
    test('todos los campos numéricos son 0', () {
      final s = OwnerMetricsSnapshot.vacio();
      expect(s.cuentasTotal, 0);
      expect(s.ingresosUsd, 0.0);
      expect(s.reviewsPromedio, 0.0);
      expect(s.flyersTasaEntrega, 0.0);
      expect(s.pagosPendientes, 0);
    });

    test('generadoEn es null', () {
      expect(OwnerMetricsSnapshot.vacio().generadoEn, isNull);
    });
  });
}
