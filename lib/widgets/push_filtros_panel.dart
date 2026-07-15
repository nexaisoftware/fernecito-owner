import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/owner_theme.dart';
import '../core/push_filtros_locales_defaults.dart';
import '../core/push_intereses.dart';
import '../core/rubros_locales.dart';
import '../core/ubicaciones_data.dart';
import '../models/push_filtros.dart';

/// Segmentación compacta: radio Todos / Avanzada + filtros por audiencia.
class PushFiltrosPanel extends StatefulWidget {
  const PushFiltrosPanel({
    super.key,
    required this.target,
    required this.filtros,
    required this.onChanged,
  });

  final String target;
  final PushFiltros filtros;
  final ValueChanged<PushFiltros> onChanged;

  @override
  State<PushFiltrosPanel> createState() => _PushFiltrosPanelState();
}

class _PushFiltrosPanelState extends State<PushFiltrosPanel> {
  final _edadMinCtrl = TextEditingController();
  final _edadMaxCtrl = TextEditingController();
  final _likesMaxCtrl = TextEditingController();
  final _califMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resetCtrls();
  }

  @override
  void didUpdateWidget(covariant PushFiltrosPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.filtros.avanzado && oldWidget.filtros.avanzado) {
      _resetCtrls();
    } else if (_fueLimpiado(oldWidget.filtros, widget.filtros)) {
      _resetCtrls();
    }
  }

  bool _fueLimpiado(PushFiltros antes, PushFiltros ahora) {
    return antes.activo && ahora.avanzado && !ahora.activo;
  }

  void _resetCtrls() {
    final f = widget.filtros;
    _edadMinCtrl.text = f.edadMin?.toString() ?? '';
    _edadMaxCtrl.text = f.edadMax?.toString() ?? '';
    _likesMaxCtrl.text = f.pocosLikesMax.toString();
    _califMaxCtrl.text = f.pocasCalificacionesMax.toString();
  }

  @override
  void dispose() {
    _edadMinCtrl.dispose();
    _edadMaxCtrl.dispose();
    _likesMaxCtrl.dispose();
    _califMaxCtrl.dispose();
    super.dispose();
  }

  bool get _usuarios =>
      widget.target == 'usuarios' || widget.target == 'ambos';
  bool get _locales => widget.target == 'locales' || widget.target == 'ambos';

  void _setModo(bool avanzado) {
    if (!avanzado) {
      widget.onChanged(const PushFiltros());
      return;
    }
    widget.onChanged(widget.filtros.copyWith(avanzado: true));
  }

  void _patch(PushFiltros next) => widget.onChanged(next);

  void _limpiarFiltros() {
    _resetCtrls();
    _patch(const PushFiltros(avanzado: true));
  }

  int? _parseEdad(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 13 || n > 99) return null;
    return n;
  }

  int? _parseUmbral(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 0 || n > PushFiltrosLocalesDefaults.maxEngagement) {
      return null;
    }
    return n;
  }

  List<String> _ciudadesDisponibles(PushFiltros f) {
    final fuente = f.provincias.isEmpty
        ? UbicacionesData.provincias
        : f.provincias;
    final set = <String>{};
    for (final p in fuente) {
      set.addAll(UbicacionesData.ciudadesDe(p));
    }
    final lista = set.toList()..sort();
    return lista;
  }

  String _resumenSeleccion(List<String> items, String vacio) {
    if (items.isEmpty) return vacio;
    if (items.length == 1) return items.first;
    return '${items.length} seleccionadas';
  }

  Future<void> _abrirSelectorMulti({
    required String titulo,
    required String subtitulo,
    required List<String> opciones,
    required List<String> seleccionados,
    required void Function(List<String>) onAplicar,
    bool conBusqueda = false,
  }) async {
    final temp = List<String>.from(seleccionados);
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final filtradas = conBusqueda && query.trim().isNotEmpty
                ? opciones
                    .where(
                      (o) => o.toLowerCase().contains(query.trim().toLowerCase()),
                    )
                    .toList()
                : opciones;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.62,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titulo,
                      style: OwnerTheme.baloo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OwnerTheme.textoSecundario,
                      ),
                    ),
                    if (conBusqueda) ...[
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Buscar ciudad…',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                        ),
                        onChanged: (v) => setModal(() => query = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filtradas.map((item) {
                            final sel = temp.contains(item);
                            return _chip(
                              label: item,
                              selected: sel,
                              onSelected: (v) => setModal(() {
                                if (v) {
                                  if (!temp.contains(item)) temp.add(item);
                                } else {
                                  temp.remove(item);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (temp.isNotEmpty)
                          TextButton(
                            onPressed: () => setModal(temp.clear),
                            child: const Text('Limpiar'),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            onAplicar(List<String>.from(temp));
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            temp.isEmpty
                                ? 'Sin filtro'
                                : 'Aplicar (${temp.length})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ubicacionPlegable(PushFiltros f) {
    final ciudadesDisp = _ciudadesDisponibles(f);
    final resumen = <String>[];
    if (f.provincias.isNotEmpty) {
      resumen.add(
        f.provincias.length == 1
            ? f.provincias.first
            : '${f.provincias.length} prov.',
      );
    }
    if (f.ciudades.isNotEmpty) {
      resumen.add(
        f.ciudades.length == 1
            ? f.ciudades.first
            : '${f.ciudades.length} ciudades',
      );
    }
    final subtitulo =
        resumen.isEmpty ? 'Todas las provincias y ciudades' : resumen.join(' · ');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        title: Text(
          'Ubicación',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: OwnerTheme.texto,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: f.provincias.isNotEmpty || f.ciudades.isNotEmpty
                ? OwnerTheme.violetaMarca
                : OwnerTheme.textoSecundario,
          ),
        ),
        iconColor: OwnerTheme.violetaMarca,
        collapsedIconColor: OwnerTheme.textoSecundario,
        children: [
          _selectorGeo(
            titulo: 'Provincia',
            hint: 'Todas las provincias',
            opciones: UbicacionesData.provincias,
            seleccionados: f.provincias,
            onAplicar: (sel) {
              final disponibles =
                  _ciudadesDisponibles(f.copyWith(provincias: sel));
              final ciudades =
                  f.ciudades.where(disponibles.contains).toList();
              _patch(f.copyWith(provincias: sel, ciudades: ciudades));
            },
          ),
          const SizedBox(height: 10),
          _selectorGeo(
            titulo: 'Ciudad',
            hint: 'Todas las ciudades',
            opciones: ciudadesDisp,
            seleccionados: f.ciudades,
            onAplicar: (sel) => _patch(f.copyWith(ciudades: sel)),
            conBusqueda: true,
            nota: f.provincias.isEmpty
                ? 'Sin provincia filtrada = ciudades de todas las provincias'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _selectorGeo({
    required String titulo,
    required String hint,
    required List<String> opciones,
    required List<String> seleccionados,
    required void Function(List<String>) onAplicar,
    bool conBusqueda = false,
    String? nota,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: _labelStyle),
        if (nota != null) ...[
          const SizedBox(height: 2),
          Text(
            nota,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: OwnerTheme.textoSecundario,
            ),
          ),
        ],
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: opciones.isEmpty
              ? null
              : () => _abrirSelectorMulti(
                    titulo: titulo,
                    subtitulo: 'Elegí una o más opciones',
                    opciones: opciones,
                    seleccionados: seleccionados,
                    onAplicar: onAplicar,
                    conBusqueda: conBusqueda,
                  ),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: BorderSide(color: OwnerTheme.borde),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _resumenSeleccion(seleccionados, hint),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: seleccionados.isNotEmpty
                        ? OwnerTheme.texto
                        : OwnerTheme.textoSecundario,
                  ),
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: OwnerTheme.textoSecundario,
              ),
            ],
          ),
        ),
        if (seleccionados.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: seleccionados
                .map(
                  (item) => InputChip(
                    label: Text(
                      item,
                      style: GoogleFonts.inter(fontSize: 10),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        OwnerTheme.violetaMarca.withValues(alpha: 0.1),
                    onDeleted: () {
                      final next = List<String>.from(seleccionados)
                        ..remove(item);
                      onAplicar(next);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filtros;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Segmentar',
              style: OwnerTheme.baloo(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _radioTile(
              title: 'Todos',
              subtitle: 'Sin filtros adicionales',
              selected: !f.avanzado,
              onTap: () => _setModo(false),
            ),
            _radioTile(
              title: 'Segmentación avanzada',
              subtitle: 'Ubicación, tipo de local, engagement…',
              selected: f.avanzado,
              onTap: () => _setModo(true),
            ),
            if (f.avanzado) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OwnerTheme.textoSecundario,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _limpiarFiltros,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ubicacionPlegable(f),
              if (_usuarios) ...[
                const SizedBox(height: 14),
                _seccionTitulo('Usuarios'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _edadMinCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Edad desde',
                          isDense: true,
                        ),
                        onChanged: (v) => _patch(
                          f.copyWith(
                            edadMin: _parseEdad(v),
                            limpiarEdadMin: v.trim().isEmpty,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _edadMaxCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Edad hasta',
                          isDense: true,
                        ),
                        onChanged: (v) => _patch(
                          f.copyWith(
                            edadMax: _parseEdad(v),
                            limpiarEdadMax: v.trim().isEmpty,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _sexoChip('Todos', null, f.sexo),
                    _sexoChip('Mujer', 'mujer', f.sexo),
                    _sexoChip('Hombre', 'hombre', f.sexo),
                    _sexoChip('Otro', 'otro', f.sexo),
                  ],
                ),
                const SizedBox(height: 8),
                _chips(
                  items: PushIntereses.chips,
                  selected: f.intereses,
                  onToggle: (chip, sel) {
                    final next = List<String>.from(f.intereses);
                    if (sel) {
                      if (next.length >= PushIntereses.maxSeleccion) return;
                      next.add(chip);
                    } else {
                      next.remove(chip);
                    }
                    _patch(f.copyWith(intereses: next));
                  },
                ),
              ],
              if (_locales) ...[
                const SizedBox(height: 14),
                _seccionTitulo('Locales'),
                const SizedBox(height: 8),
                Text('Rubros', style: _labelStyle),
                const SizedBox(height: 6),
                _chips(
                  items: RubrosLocales.todos,
                  selected: f.rubros,
                  onToggle: (chip, sel) {
                    final next = List<String>.from(f.rubros);
                    if (sel) {
                      next.add(chip);
                    } else {
                      next.remove(chip);
                    }
                    _patch(f.copyWith(rubros: next));
                  },
                ),
                const SizedBox(height: 10),
                Text('Tipo comercial', style: _labelStyle),
                const SizedBox(height: 6),
                _chips(
                  items: const ['Gratis', 'Plan pago', 'Pioneros'],
                  selected: f.tiposComercialesLocal.map(_tipoApiToUi).toList(),
                  onToggle: (label, sel) {
                    final api = _tipoUiToApi(label);
                    if (api == null) return;
                    final next = List<String>.from(f.tiposComercialesLocal);
                    if (sel) {
                      next.add(api);
                    } else {
                      next.remove(api);
                    }
                    _patch(f.copyWith(tiposComercialesLocal: next));
                  },
                ),
                const SizedBox(height: 10),
                Text('Oportunidades', style: _labelStyle),
                const SizedBox(height: 6),
                _oportunidadToggle(
                  label: 'Pocos likes',
                  activo: f.filtroPocosLikes,
                  ctrl: _likesMaxCtrl,
                  onToggle: (v) => _patch(
                    f.copyWith(
                      filtroPocosLikes: v,
                      pocosLikesMax: v
                          ? (_parseUmbral(_likesMaxCtrl.text) ??
                              PushFiltrosLocalesDefaults.pocosLikesMax)
                          : PushFiltrosLocalesDefaults.pocosLikesMax,
                    ),
                  ),
                  onMaxChanged: (n) => _patch(
                    f.copyWith(
                      pocosLikesMax:
                          n ?? PushFiltrosLocalesDefaults.pocosLikesMax,
                    ),
                  ),
                ),
                _oportunidadToggle(
                  label: 'Pocas calificaciones',
                  activo: f.filtroPocasCalificaciones,
                  ctrl: _califMaxCtrl,
                  onToggle: (v) => _patch(
                    f.copyWith(
                      filtroPocasCalificaciones: v,
                      pocasCalificacionesMax: v
                          ? (_parseUmbral(_califMaxCtrl.text) ??
                              PushFiltrosLocalesDefaults.pocasCalificacionesMax)
                          : PushFiltrosLocalesDefaults.pocasCalificacionesMax,
                    ),
                  ),
                  onMaxChanged: (n) => _patch(
                    f.copyWith(
                      pocasCalificacionesMax: n ??
                          PushFiltrosLocalesDefaults.pocasCalificacionesMax,
                    ),
                  ),
                ),
                _chip(
                  label: 'Sin eventos activos',
                  selected: f.sinEventosActivos,
                  onSelected: (v) => _patch(f.copyWith(sinEventosActivos: v)),
                ),
              ],
            ],
            if (f.activo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: OwnerTheme.fondo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OwnerTheme.borde),
                ),
                child: Text(
                  f.resumenCompacto(target: widget.target),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: OwnerTheme.texto,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: OwnerTheme.textoSecundario,
      );

  Widget _seccionTitulo(String t) => Text(
        t,
        style: OwnerTheme.baloo(fontSize: 14, fontWeight: FontWeight.w800),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : OwnerTheme.texto,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: OwnerTheme.violetaMarca,
      backgroundColor: OwnerTheme.fondo,
      side: BorderSide(
        color: selected ? OwnerTheme.violetaMarca : OwnerTheme.borde,
      ),
      onSelected: onSelected,
    );
  }

  Widget _chips({
    required List<String> items,
    required List<String> selected,
    required void Function(String chip, bool sel) onToggle,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (chip) => _chip(
              label: chip,
              selected: selected.contains(chip),
              onSelected: (v) => onToggle(chip, v),
            ),
          )
          .toList(),
    );
  }

  Widget _oportunidadToggle({
    required String label,
    required bool activo,
    required TextEditingController ctrl,
    required ValueChanged<bool> onToggle,
    required ValueChanged<int?> onMaxChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          _chip(label: label, selected: activo, onSelected: onToggle),
          if (activo) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: '≤',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (v) => onMaxChanged(_parseUmbral(v)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _tipoUiToApi(String label) => switch (label) {
        'Gratis' => 'gratis',
        'Plan pago' => 'plan_pago',
        'Pioneros' => 'pionero',
        _ => null,
      };

  String _tipoApiToUi(String api) => switch (api) {
        'gratis' => 'Gratis',
        'plan_pago' => 'Plan pago',
        'pionero' => 'Pioneros',
        _ => api,
      };

  Widget _radioTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? OwnerTheme.violetaMarca
                  : OwnerTheme.textoSecundario,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: OwnerTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sexoChip(String label, String? value, String? actual) {
    final sel = value == null
        ? (actual == null || actual.isEmpty)
        : actual == value;
    return _chip(
      label: label,
      selected: sel,
      onSelected: (_) => _patch(
        widget.filtros.copyWith(sexo: value, limpiarSexo: value == null),
      ),
    );
  }
}
