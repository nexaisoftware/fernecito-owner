import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend_owner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Owner Dashboard - Smoke Tests', () {
    testWidgets('La app de Owner arranca y muestra la pantalla de login o home', (tester) async {
      // Inicia la aplicación completa
      app.main();
      await tester.pumpAndSettle();

      // Buscamos elementos que sabemos que deberían aparecer
      // Ya sea el título del login o algo del dashboard
      final hasLoginTitle = find.textContaining('Fernecito Owner').evaluate().isNotEmpty ||
          find.textContaining('Acceso restringido').evaluate().isNotEmpty;

      final hasNavigation = find.byType(NavigationRail).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;

      // La app debería mostrar algo reconocible
      expect(
        hasLoginTitle || hasNavigation,
        isTrue,
        reason: 'La app debería mostrar o la pantalla de login o la navegación del dashboard',
      );
    });

    // Ejemplo de cómo se vería un test más real cuando tengamos mocks
    // testWidgets('Métricas carga y muestra cards', (tester) async {
    //   // Aquí mockearíamos el OwnerMetricsService
    //   // Navegaríamos a la pestaña de Métricas
    //   // Verificaríamos que aparecen las cards con números
    // });
  });
}