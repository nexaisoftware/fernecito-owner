import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/motivos_pausa_cuenta.dart';
import '../core/owner_theme.dart';
import '../services/owner_admin_service.dart';
import 'admin_detalle_screen.dart';

class ModeracionOwnerScreen extends StatefulWidget {
  const ModeracionOwnerScreen({super.key});

  @override
  State<ModeracionOwnerScreen> createState() => _ModeracionOwnerScreenState();
}

class _ModeracionOwnerScreenState extends State<ModeracionOwnerScreen> {
  bool _loading = true;
  bool _procesando = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await OwnerAdminService.instance.listarReportes();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar reportes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pausar(Map<String, dynamic> item) async {
    var tipo = item['target_tipo']?.toString() ?? '';
    var id = item['target_id']?.toString() ?? '';
    final esEvento = tipo == 'evento';
    // Un evento reportado se modera pausando al LOCAL dueño del evento.
    if (esEvento) {
      tipo = 'local';
      id = item['evento_local_id']?.toString() ?? '';
    }
    if (tipo.isEmpty || id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esEvento ? 'Pausar local del evento' : 'Pausar cuenta'),
        content: Text(
          '${esEvento ? 'Se pausará el LOCAL dueño de esta publicación por reportes reiterados.\n\n' : 'Se pausará esta cuenta por reportes reiterados.\n\n'}'
          'Motivo principal: ${item['motivo_top_label'] ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pausar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    try {
      final motivoPublico = motivosPausaPublicos
          .firstWhere(
            (m) => m.codigo == 'reportes_usuarios',
            orElse: () => motivosPausaPublicos.first,
          )
          .etiqueta;
      final res = await OwnerAdminService.instance.pausarCuenta(
        targetId: id,
        tipo: tipo,
        pausar: true,
        motivo:
            'Pausa desde Moderacion. Reportes: ${item['cantidad_reportes']}. Motivo top: ${item['motivo_top_label']}.',
        motivoPublico: motivoPublico,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['ok'] == true
                ? 'Cuenta pausada'
                : (res['error']?.toString() ?? 'Error'),
          ),
        ),
      );
      if (res['ok'] == true) await _cargar();
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _limpiarReportes(Map<String, dynamic> item) async {
    final tipo = item['target_tipo']?.toString() ?? '';
    final id = item['target_id']?.toString() ?? '';
    final count = (item['cantidad_reportes'] as num?)?.toInt() ?? 0;
    if (tipo.isEmpty || id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar reportes'),
        content: Text(
          'Se eliminarán los $count reportes acumulados de esta cuenta.\n\n'
          'La cuenta no se pausa ni se reactiva: solo desaparece de Moderación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    try {
      final res = await OwnerAdminService.instance.eliminarReportesCuenta(
        targetTipo: tipo,
        targetId: id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['ok'] == true
                ? 'Reportes eliminados'
                : (res['error']?.toString() ?? 'Error'),
          ),
        ),
      );
      if (res['ok'] == true) await _cargar();
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _abrirDetalle(Map<String, dynamic> item) {
    var tipo = item['target_tipo']?.toString() ?? 'usuario';
    var id = item['target_id']?.toString() ?? '';
    var nombre =
        item['username']?.toString() ??
        item['nombre']?.toString() ??
        'Reportado';
    // En eventos el detalle apunta al LOCAL dueño (no hay detalle de evento).
    if (tipo == 'evento') {
      tipo = 'local';
      id = item['evento_local_id']?.toString() ?? '';
      nombre =
          item['evento_local_username']?.toString() ??
          item['evento_local_nombre']?.toString() ??
          'Local';
    }
    if (id.isEmpty) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminDetalleScreen(
              tipo: tipo,
              targetId: id,
              nombreInicial: nombre,
            ),
          ),
        )
        .then((_) => _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerTheme.fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: OwnerTheme.superficie,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Moderacion',
                    style: OwnerTheme.baloo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: OwnerTheme.texto,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _loading ? null : _cargar,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                _error!,
                style: GoogleFonts.inter(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('Sin perfiles reportados'))
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _items.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReporteCard(
                        item: _items[i],
                        procesando: _procesando,
                        onTap: () => _abrirDetalle(_items[i]),
                        onPausar: () => _pausar(_items[i]),
                        onLimpiar: () => _limpiarReportes(_items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  const _ReporteCard({
    required this.item,
    required this.procesando,
    required this.onTap,
    required this.onPausar,
    required this.onLimpiar,
  });

  final Map<String, dynamic> item;
  final bool procesando;
  final VoidCallback onTap;
  final VoidCallback onPausar;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final count = (item['cantidad_reportes'] as num?)?.toInt() ?? 0;
    final urgente = count > 4;
    final tipo = item['target_tipo']?.toString() ?? '';
    final username = item['username']?.toString() ?? '';
    final nombre = item['nombre']?.toString() ?? '';
    final estado = item['estado_cuenta']?.toString() ?? 'activa';
    final reportantes = item['reportantes'] is List
        ? item['reportantes'] as List
        : const [];
    final esEvento = tipo == 'evento';
    final flyer = item['evento_flyer']?.toString() ?? '';
    final eventoTitulo = item['evento_titulo']?.toString() ?? nombre;
    final localUser = item['evento_local_username']?.toString() ?? '';
    final localNombre = item['evento_local_nombre']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgente ? const Color(0xFFEF4444) : OwnerTheme.borde,
              width: urgente ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (esEvento)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 42,
                        height: 56,
                        child: flyer.isNotEmpty
                            ? Image.network(
                                flyer,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: const Color(0xFFEEEEEE),
                                      child: const Icon(
                                        Icons.movie_rounded,
                                        color: Colors.black38,
                                      ),
                                    ),
                              )
                            : Container(
                                color: const Color(0xFFEEEEEE),
                                child: const Icon(
                                  Icons.movie_rounded,
                                  color: Colors.black38,
                                ),
                              ),
                      ),
                    )
                  else
                    Icon(
                      tipo == 'local'
                          ? Icons.storefront_rounded
                          : Icons.person_rounded,
                      color: urgente
                          ? const Color(0xFFEF4444)
                          : OwnerTheme.violetaMarca,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esEvento
                              ? eventoTitulo
                              : (username.isNotEmpty ? '@$username' : nombre),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          esEvento
                              ? 'Evento · ${localUser.isNotEmpty ? '@$localUser' : (localNombre.isNotEmpty ? localNombre : 'local')} · $count reportes'
                              : '$tipo · $estado · $count reportes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (urgente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '5+',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Motivo principal: ${item['motivo_top_label'] ?? '-'} (${item['cantidad_motivo_top'] ?? 0})',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (reportantes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Reportantes: ${reportantes.map((r) {
                    final m = r is Map ? r : {};
                    final u = m['username']?.toString() ?? m['nombre']?.toString() ?? m['id']?.toString() ?? '?';
                    return '@$u';
                  }).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Detalle'),
                  ),
                  FilledButton.icon(
                    onPressed: procesando || estado == 'pausada'
                        ? null
                        : onPausar,
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: Text(estado == 'pausada' ? 'Pausada' : 'Pausar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: procesando ? null : onLimpiar,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Limpiar reportes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
