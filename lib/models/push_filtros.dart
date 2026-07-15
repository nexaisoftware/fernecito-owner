import '../core/push_filtros_locales_defaults.dart';

/// Filtros opcionales para envío push segmentado (validados server-side).
class PushFiltros {
  const PushFiltros({
    this.avanzado = false,
    this.provincias = const [],
    this.ciudades = const [],
    this.edadMin,
    this.edadMax,
    this.sexo,
    this.intereses = const [],
    this.rubros = const [],
    this.tiposComercialesLocal = const [],
    this.filtroPocosLikes = false,
    this.pocosLikesMax = PushFiltrosLocalesDefaults.pocosLikesMax,
    this.filtroPocasCalificaciones = false,
    this.pocasCalificacionesMax = PushFiltrosLocalesDefaults.pocasCalificacionesMax,
    this.sinEventosActivos = false,
  });

  final bool avanzado;
  final List<String> provincias;
  final List<String> ciudades;
  final int? edadMin;
  final int? edadMax;
  final String? sexo;
  final List<String> intereses;
  final List<String> rubros;
  final List<String> tiposComercialesLocal;
  final bool filtroPocosLikes;
  final int pocosLikesMax;
  final bool filtroPocasCalificaciones;
  final int pocasCalificacionesMax;
  final bool sinEventosActivos;

  bool get activo =>
      avanzado &&
      (_tieneGeo ||
          _tieneUsuarios ||
          _tieneLocales);

  bool get _tieneGeo => provincias.isNotEmpty || ciudades.isNotEmpty;

  bool get _tieneUsuarios =>
      edadMin != null ||
      edadMax != null ||
      (sexo != null && sexo!.isNotEmpty) ||
      intereses.isNotEmpty;

  bool get _tieneLocales =>
      rubros.isNotEmpty ||
      tiposComercialesLocal.isNotEmpty ||
      filtroPocosLikes ||
      filtroPocasCalificaciones ||
      sinEventosActivos;

  Map<String, dynamic> toJson() {
    if (!activo) return {};
    final map = <String, dynamic>{};
    if (provincias.isNotEmpty) map['provincias'] = provincias;
    if (ciudades.isNotEmpty) map['ciudades'] = ciudades;
    if (edadMin != null) map['edadMin'] = edadMin;
    if (edadMax != null) map['edadMax'] = edadMax;
    if (sexo != null && sexo!.isNotEmpty) map['sexo'] = sexo;
    if (intereses.isNotEmpty) {
      map['intereses'] = intereses.map((i) => i.toLowerCase()).toList();
    }
    if (rubros.isNotEmpty) map['rubros'] = rubros;
    if (tiposComercialesLocal.isNotEmpty) {
      map['tiposComercialesLocal'] = tiposComercialesLocal;
    }
    if (filtroPocosLikes) map['pocosLikesMax'] = pocosLikesMax;
    if (filtroPocasCalificaciones) {
      map['pocasCalificacionesMax'] = pocasCalificacionesMax;
    }
    if (sinEventosActivos) map['sinEventosActivos'] = true;
    return map;
  }

  String destinoLabel(String target) => switch (target) {
        'locales' => 'Locales',
        'ambos' => 'Ambos',
        _ => 'Usuarios',
      };

  String resumenCompacto({required String target}) {
    if (!activo) return 'Todos';

    if (target == 'locales') return _resumenLocales();
    if (target == 'usuarios') return _resumenUsuarios();
    return _resumenAmbos();
  }

  String _resumenUsuarios() {
    final p = <String>['Usuarios'];
    _agregarGeo(p);
    if (edadMin != null || edadMax != null) {
      p.add('${edadMin ?? '…'}-${edadMax ?? '…'}');
    }
    if (sexo != null && sexo!.isNotEmpty) p.add(_sexoLabel(sexo!));
    if (intereses.isNotEmpty) p.add(intereses.join(', '));
    return p.join(' · ');
  }

  String _resumenLocales() {
    final p = <String>['Locales'];
    _agregarGeo(p);
    if (rubros.isNotEmpty) p.add(rubros.join('/'));
    if (tiposComercialesLocal.isNotEmpty) {
      p.add(tiposComercialesLocal.map(_tipoComercialLabel).join(' + '));
    }
    _agregarOportunidades(p);
    return p.join(' · ');
  }

  String _resumenAmbos() {
    final p = <String>['Ambos'];
    _agregarGeo(p);
    if (_tieneUsuarios) {
      final u = <String>[];
      if (edadMin != null || edadMax != null) {
        u.add('${edadMin ?? '…'}-${edadMax ?? '…'}');
      }
      if (sexo != null && sexo!.isNotEmpty) u.add(_sexoLabel(sexo!));
      if (intereses.isNotEmpty) u.add(intereses.join(', '));
      if (u.isNotEmpty) p.add('Usu: ${u.join(', ')}');
    }
    if (_tieneLocales) {
      final l = <String>[];
      if (rubros.isNotEmpty) l.add(rubros.join('/'));
      if (tiposComercialesLocal.isNotEmpty) {
        l.add(tiposComercialesLocal.map(_tipoComercialLabel).join('+'));
      }
      if (filtroPocosLikes) l.add('likes≤$pocosLikesMax');
      if (filtroPocasCalificaciones) l.add('calif≤$pocasCalificacionesMax');
      if (sinEventosActivos) l.add('sin eventos');
      if (l.isNotEmpty) p.add('Loc: ${l.join(', ')}');
    }
    return p.join(' · ');
  }

  void _agregarGeo(List<String> p) {
    if (provincias.isNotEmpty) p.add(provincias.join(' + '));
    if (ciudades.isNotEmpty) p.add(ciudades.join(' + '));
  }

  void _agregarOportunidades(List<String> p) {
    if (filtroPocosLikes) p.add('Pocos likes ≤$pocosLikesMax');
    if (filtroPocasCalificaciones) {
      p.add('Pocas calif. ≤$pocasCalificacionesMax');
    }
    if (sinEventosActivos) p.add('Sin eventos activos');
  }

  String resumenDetalle({required String target}) {
    if (!activo) {
      return 'Sin filtros: se enviará a todos los dispositivos del segmento elegido.';
    }

    final lineas = <String>['Destino: ${destinoLabel(target)}'];
    if (provincias.isNotEmpty) {
      lineas.add('Provincias: ${provincias.join(', ')}');
    }
    if (ciudades.isNotEmpty) {
      lineas.add('Ciudades: ${ciudades.join(', ')}');
    }

    if (target != 'locales') {
      if (edadMin != null || edadMax != null) {
        lineas.add('Edad: ${edadMin ?? '…'} a ${edadMax ?? '…'}');
      }
      if (sexo != null && sexo!.isNotEmpty) {
        lineas.add('Sexo: ${_sexoLabel(sexo!)}');
      }
      if (intereses.isNotEmpty) {
        lineas.add('Intereses (actividad): ${intereses.join(', ')}');
      }
    }

    if (target != 'usuarios') {
      if (rubros.isNotEmpty) lineas.add('Rubros: ${rubros.join(', ')}');
      if (tiposComercialesLocal.isNotEmpty) {
        lineas.add(
          'Tipo comercial: ${tiposComercialesLocal.map(_tipoComercialLabel).join(', ')}',
        );
      }
      if (filtroPocosLikes) {
        lineas.add('Pocos likes: ≤ $pocosLikesMax');
      }
      if (filtroPocasCalificaciones) {
        lineas.add('Pocas calificaciones: ≤ $pocasCalificacionesMax');
      }
      if (sinEventosActivos) {
        lineas.add('Sin eventos publicados activos en cartelera');
      }
    }

    if (target == 'ambos') {
      lineas.add(
        'Nota: filtros de usuarios y locales se aplican por separado a cada app.',
      );
    }

    return lineas.join('\n');
  }

  static String _sexoLabel(String s) => switch (s) {
        'mujer' => 'Mujer',
        'hombre' => 'Hombre',
        _ => 'Otro / No especificado',
      };

  static String _tipoComercialLabel(String s) => switch (s) {
        'gratis' => 'Gratis',
        'plan_pago' => 'Plan pago',
        'pionero' => 'Pioneros',
        _ => s,
      };

  PushFiltros copyWith({
    bool? avanzado,
    List<String>? provincias,
    List<String>? ciudades,
    int? edadMin,
    int? edadMax,
    String? sexo,
    List<String>? intereses,
    List<String>? rubros,
    List<String>? tiposComercialesLocal,
    bool? filtroPocosLikes,
    int? pocosLikesMax,
    bool? filtroPocasCalificaciones,
    int? pocasCalificacionesMax,
    bool? sinEventosActivos,
    bool limpiarEdadMin = false,
    bool limpiarEdadMax = false,
    bool limpiarSexo = false,
  }) {
    return PushFiltros(
      avanzado: avanzado ?? this.avanzado,
      provincias: provincias ?? this.provincias,
      ciudades: ciudades ?? this.ciudades,
      edadMin: limpiarEdadMin ? null : (edadMin ?? this.edadMin),
      edadMax: limpiarEdadMax ? null : (edadMax ?? this.edadMax),
      sexo: limpiarSexo ? null : (sexo ?? this.sexo),
      intereses: intereses ?? this.intereses,
      rubros: rubros ?? this.rubros,
      tiposComercialesLocal: tiposComercialesLocal ?? this.tiposComercialesLocal,
      filtroPocosLikes: filtroPocosLikes ?? this.filtroPocosLikes,
      pocosLikesMax: pocosLikesMax ?? this.pocosLikesMax,
      filtroPocasCalificaciones:
          filtroPocasCalificaciones ?? this.filtroPocasCalificaciones,
      pocasCalificacionesMax:
          pocasCalificacionesMax ?? this.pocasCalificacionesMax,
      sinEventosActivos: sinEventosActivos ?? this.sinEventosActivos,
    );
  }
}

String pushSegmentoLegible(String segmento) {
  if (segmento.isEmpty) return 'Todos';
  final parts = segmento.split(':');
  if (parts.length == 1) {
    return switch (parts[0]) {
      'locales' => 'Locales · todos',
      'ambos' => 'Ambos · todos',
      _ => 'Usuarios · todos',
    };
  }

  final baseLabel = switch (parts[0]) {
    'locales' => 'Locales',
    'ambos' => 'Ambos',
    _ => 'Usuarios',
  };

  final detalle = parts
      .sublist(1)
      .join(' · ')
      .replaceAll('/', ' · ')
      .replaceAll('pocos_likes<=', 'likes≤')
      .replaceAll('pocas_calif<=', 'calif≤')
      .replaceAll('sin_eventos', 'sin eventos');
  return '$baseLabel · $detalle';
}
