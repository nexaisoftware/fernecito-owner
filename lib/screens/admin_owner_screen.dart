import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/owner_theme.dart';
import '../services/owner_admin_service.dart';
import 'admin_detalle_screen.dart';

/// Panel de administración:
/// - Toggle Locales / Usuarios
/// - Buscador libre (debounce)
/// - Lista de resultados → tap abre detalle con acciones
class AdminOwnerScreen extends StatefulWidget {
  const AdminOwnerScreen({super.key});

  @override
  State<AdminOwnerScreen> createState() => _AdminOwnerScreenState();
}

class _AdminOwnerScreenState extends State<AdminOwnerScreen> {
  String _tipo = 'local'; // 'local' | 'usuario'
  final _searchCtl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar(''); // carga inicial vacía → trae los primeros 30
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _buscar(v));
  }

  Future<void> _buscar(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = OwnerAdminService.instance;
      final lista = _tipo == 'local'
          ? await svc.buscarLocales(q)
          : await svc.buscarUsuarios(q);
      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error en búsqueda: $e';
        _loading = false;
      });
    }
  }

  void _abrirDetalle(Map<String, dynamic> item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminDetalleScreen(
        tipo: _tipo,
        targetId: item['id'].toString(),
        nombreInicial: _tipo == 'local'
            ? (item['local_username']?.toString() ?? item['nombre_local']?.toString() ?? '?')
            : (item['username']?.toString() ?? '?'),
      ),
    )).then((_) => _buscar(_searchCtl.text));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;

    return ColoredBox(
      color: OwnerTheme.fondo,
      child: Column(
        children: [
          _header(compact),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: OwnerTheme.baloo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? _emptyState()
                    : _lista(),
          ),
        ],
      ),
    );
  }

  Widget _header(bool compact) {
    return Container(
      color: OwnerTheme.superficie,
      padding: EdgeInsets.fromLTRB(compact ? 14 : 16, 16, compact ? 14 : 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Admin',
                  style: OwnerTheme.baloo(
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w900,
                    color: OwnerTheme.texto,
                  ),
                ),
              ),
              _tipoSwitch(compact),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtl,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _tipo == 'local'
                  ? 'Buscar local por @username o nombre…'
                  : 'Buscar usuario por @username o nombre…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtl.clear();
                        _buscar('');
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoSwitch(bool compact) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: 'local',
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: compact
              ? null
              : Text('Locales', style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w800)),
          tooltip: compact ? 'Locales' : null,
        ),
        ButtonSegment<String>(
          value: 'usuario',
          icon: const Icon(Icons.person_rounded, size: 18),
          label: compact
              ? null
              : Text('Usuarios', style: OwnerTheme.baloo(fontSize: 12, fontWeight: FontWeight.w800)),
          tooltip: compact ? 'Usuarios' : null,
        ),
      ],
      selected: {_tipo},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        setState(() => _tipo = s.first);
        _buscar(_searchCtl.text);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 10),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: OwnerTheme.borde)),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OwnerTheme.violetaMarca;
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
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'Sin resultados',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtl.text.isEmpty
                  ? 'Empezá a escribir para buscar.'
                  : 'No encontramos coincidencias para "${_searchCtl.text}"',
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ItemCard(
        item: _resultados[i],
        tipo: _tipo,
        onTap: () => _abrirDetalle(_resultados[i]),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String tipo;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final esLocal = tipo == 'local';
    final username = esLocal
        ? (item['local_username']?.toString() ?? '?')
        : (item['username']?.toString() ?? '?');
    final nombre = esLocal
        ? (item['nombre_local']?.toString() ?? '')
        : (item['nombre']?.toString() ?? '');
    final foto = item['foto_perfil_url']?.toString();
    final estado = item['estado_cuenta']?.toString() ?? 'activa';
    final plan = esLocal ? (item['plan_suscripcion']?.toString() ?? 'gratis') : null;
    final verificado = item['local_verificado'] == true;
    final esPionero = item['es_pionero'] == true;
    final ciudad = item['ciudad']?.toString() ?? '';
    final pausada = estado == 'pausada';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pausada
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                  : const Color(0xFFEAE6F5),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Avatar(url: foto, fallback: username),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@$username',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (verificado) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 13,
                            color: esPionero ? const Color(0xFFE0B800) : const Color(0xFF0EA5E9),
                          ),
                        ],
                        if (esPionero) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0B800),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'P',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF3B2F00),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (nombre.isNotEmpty)
                      Text(nombre,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    if (ciudad.isNotEmpty)
                      Text(ciudad,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pausada)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'PAUSADA',
                        style: GoogleFonts.inter(
                            fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    )
                  else if (plan != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _planColor(plan),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        plan.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _planColor(String p) {
    switch (p.toLowerCase()) {
      case 'standard':
        return const Color(0xFF6366F1);
      case 'plus':
        return const Color(0xFF0891B2);
      case 'premium':
        return const Color(0xFFF59E0B);
      case 'pionero':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String fallback;
  const _Avatar({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isNotEmpty ? fallback[0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFEDE9FE),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEDE9FE),
      child: Text(
        initial,
        style: GoogleFonts.inter(color: const Color(0xFF5A2EFF), fontWeight: FontWeight.w900),
      ),
    );
  }
}

// Helper para usar desde admin_detalle_screen
String formatearFechaCorta(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final d = DateTime.tryParse(iso);
  if (d == null) return '-';
  return DateFormat('dd/MM/yyyy').format(d.toLocal());
}
