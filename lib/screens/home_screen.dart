import 'package:flutter/material.dart';

import '../core/owner_theme.dart';
import '../services/owner_service.dart';
import '../widgets/app_logo_image.dart';
import 'admin_owner_screen.dart';
import 'metricas_owner_screen.dart';
import 'moderacion_owner_screen.dart';
import 'notificar_owner_screen.dart';
import 'pagos_owner_screen.dart';
import 'soporte_owner_screen.dart';

enum _NavModulo {
  pagos(Icons.payments_rounded, 'Pagos'),
  metricas(Icons.bar_chart_rounded, 'Métricas'),
  notificar(Icons.campaign_rounded, 'Notificar'),
  soporte(Icons.support_agent_rounded, 'Soporte'),
  moderacion(Icons.report_problem_rounded, 'Moderación'),
  admin(Icons.admin_panel_settings_rounded, 'Admin');

  const _NavModulo(this.icon, this.label);

  final IconData icon;
  final String label;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _NavModulo _modulo = _NavModulo.pagos;

  static const _desktopBreakpoint = 900.0;

  static const _modulos = _NavModulo.values;

  Widget _moduloContent(_NavModulo modulo) {
    return switch (modulo) {
      _NavModulo.pagos => const PagosOwnerScreen(),
      _NavModulo.metricas => const MetricasOwnerScreen(),
      _NavModulo.notificar => const NotificarOwnerScreen(),
      _NavModulo.soporte => const SoporteOwnerScreen(),
      _NavModulo.moderacion => const ModeracionOwnerScreen(),
      _NavModulo.admin => const AdminOwnerScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final email = OwnerService.instance.currentUser?.email ?? '';
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: OwnerTheme.fondo,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoImage(size: 32),
            const SizedBox(width: 10),
            Text(
              'Fernecito Owner',
              style: OwnerTheme.baloo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: OwnerTheme.texto,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await OwnerService.instance.signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'me',
                enabled: false,
                child: Text(email, style: const TextStyle(fontSize: 13)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: OwnerTheme.violetaMarca.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: OwnerTheme.violetaMarca,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _modulo.index,
                  onDestinationSelected: (i) =>
                      setState(() => _modulo = _modulos[i]),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: OwnerTheme.superficie,
                  selectedIconTheme: IconThemeData(
                    color: OwnerTheme.violetaMarca,
                  ),
                  selectedLabelTextStyle: OwnerTheme.baloo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: OwnerTheme.violetaMarca,
                  ),
                  unselectedLabelTextStyle: OwnerTheme.baloo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OwnerTheme.textoSecundario,
                  ),
                  destinations: _modulos
                      .map(
                        (m) => NavigationRailDestination(
                          icon: Icon(m.icon),
                          label: Text(m.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _moduloContent(_modulo)),
              ],
            )
          : IndexedStack(
              index: _modulo.index,
              children: _modulos.map(_moduloContent).toList(),
            ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _modulo.index,
              onDestinationSelected: (i) =>
                  setState(() => _modulo = _modulos[i]),
              backgroundColor: OwnerTheme.superficie,
              indicatorColor: OwnerTheme.violetaMarca.withValues(alpha: 0.12),
              destinations: _modulos
                  .map(
                    (m) => NavigationDestination(
                      icon: Icon(m.icon),
                      label: m.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
