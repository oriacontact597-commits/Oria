// test/scenarios_types_screen_test.dart
//
// Smoke test du widget ScenariosTypesScreen.
// Vérifie que l'écran affiche un CircularProgressIndicator au démarrage
// (avant que l'appel HTTP ne se résolve) et un AppBar avec le bon titre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oria_education/screens/simulateur/scenarios_types_screen.dart';

void main() {
  testWidgets('ScenariosTypesScreen affiche un loader au démarrage',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScenariosTypesScreen(),
      ),
    );

    // Avant que pump() ne déclenche la fin du Future HTTP, on doit voir
    // un CircularProgressIndicator (le service va probablement timeout
    // en test, ce qui est attendu : on veut juste vérifier l'état initial).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Scénarios types'), findsOneWidget);

    // On laisse l'event loop avancer un peu puis on vérifie que
    // l'écran ne crash pas (pas d'exception).
    await tester.pump(const Duration(milliseconds: 100));
  });
}
