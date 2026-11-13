import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviles_auth/components/session_guard.dart';

void main() {
  for (final route in ['/home', '/compose']) {
    testWidgets(
      '$route without a session redirects before building the screen',
      (tester) async {
        var protectedBuilds = 0;
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: route,
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login')),
              route: (_) => SessionGuard(
                hasSession: () => false,
                builder: (_) {
                  protectedBuilds++;
                  return const Text('Protected');
                },
              ),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Login'), findsOneWidget);
        expect(protectedBuilds, 0);
        expect(tester.takeException(), isNull);
        final context = tester.element(find.text('Login'));
        expect(ModalRoute.of(context)!.settings.name, '/login');
        expect(Navigator.of(context).canPop(), isFalse);
      },
    );
  }

  testWidgets('an authenticated user can open the protected screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionGuard(
          hasSession: () => true,
          builder: (_) => const Scaffold(body: Text('Muro')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Muro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
