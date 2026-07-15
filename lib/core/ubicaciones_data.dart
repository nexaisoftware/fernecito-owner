/// Datos geográficos compartidos para Fernecito MVP.
///
/// 🔁 SYNC: espejo de `frontend_locales/lib/core/ubicaciones_data.dart` y
/// `fernecito_frontend/lib/core/ubicaciones_data.dart`.
library;

class UbicacionesData {
  UbicacionesData._();

  static const String provinciaPorDefecto = 'Córdoba';

  static const List<String> provincias = <String>[
    'Córdoba',
  ];

  static const Map<String, List<String>> ciudadesPorProvincia =
      <String, List<String>>{
    'Córdoba': <String>[
      'Córdoba capital',
      'Alta Gracia',
      'Bell Ville',
      'Bialet Massé',
      'Capilla del Monte',
      'Colonia Caroya',
      'Cosquín',
      'Embalse',
      'Hernando',
      'Jesús María',
      'La Calera',
      'La Falda',
      'Malagueño',
      'Marcos Juárez',
      'Mendiolaza',
      'Mina Clavero',
      'Nono',
      'Río Ceballos',
      'Río Cuarto',
      'Río Tercero',
      'Saldán',
      'San Francisco',
      'Santa María de Punilla',
      'Unquillo',
      'Villa Allende',
      'Villa Carlos Paz',
      'Villa Cura Brochero',
      'Villa María',
      'Villa Nueva',
    ],
  };

  static List<String> ciudadesDe(String provincia) =>
      ciudadesPorProvincia[provincia] ?? const <String>[];

  static String get ciudadPorDefecto =>
      ciudadesDe(provinciaPorDefecto).first;
}
