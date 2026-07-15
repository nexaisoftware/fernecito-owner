import 'package:flutter/material.dart';

import '../core/owner_nav_modulo.dart';
import '../core/owner_theme.dart';
import '../core/servicio_push_owner.dart';
import '../services/owner_service.dart';
import '../widgets/app_logo_image.dart';
import '../widgets/dialog_permiso_push_owner.dart';
import 'dashboard_owner_screen.dart';
import 'metricas_owner_screen.dart';
import 'moderacion_owner_screen.dart';
import 'soporte_owner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OwnerNavModulo _modulo = OwnerNavModulo.dashboard;

  static const _desktopBreakpoint = 900.0;
  static const _modulos = OwnerNavModulo.values;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogPermisoPushOwner.mostrarSiCorresponde(context);
    });
  }

  void _irAModulo(OwnerNavModulo modulo) {
    setState(() => _modulo = modulo);
  }

  Widget _moduloContent(OwnerNavModulo modulo) {
    return switch (modulo) {
      OwnerNavModulo.metricas => const MetricasOwnerScreen(),
      OwnerNavModulo.soporte => const SoporteOwnerScreen(),
      OwnerNavModulo.moderacion => const ModeracionOwnerScreen(),
      OwnerNavModulo.dashboard => DashboardOwnerScreen(onIrAModulo: _irAModulo),
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
                ServicioPushOwner.instancia.olvidarLocal();
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
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
