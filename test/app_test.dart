import 'package:dawat/app.dart';
import 'package:dawat/data/demo/demo_backend.dart';
import 'package:dawat/logic/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DawatApp(backend: DemoBackend(), settings: AppSettings()));
    await tester.pumpAndSettle();
  }

  Future<void> signInAs(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('welcome screen offers sign-up, sign-in and demo accounts', (tester) async {
    await boot(tester);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Bride & Groom'), findsOneWidget);
  });

  testWidgets('couple sees the countdown and can open every tab', (tester) async {
    await boot(tester);
    await signInAs(tester, 'Bride & Groom');
    expect(find.text('days to go'), findsOneWidget);
    expect(find.text('Shno & Aram'), findsOneWidget);

    for (final tab in ['Vendors', 'Checklist', 'Budget', 'More']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)));
      await tester.pumpAndSettle();
    }
    expect(find.text('My bookings'), findsOneWidget);
  });

  testWidgets('provider sees requests waiting', (tester) async {
    await boot(tester);
    await signInAs(tester, 'Provider');
    expect(find.text('Lalav Hall'), findsWidgets);
    expect(find.text('Requests waiting'), findsOneWidget);
  });

  testWidgets('admin sees providers awaiting approval', (tester) async {
    await boot(tester);
    await signInAs(tester, 'Admin');
    expect(find.text('Awaiting approval'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Providers')));
    await tester.pumpAndSettle();
    expect(find.text('Rozh Photography'), findsOneWidget);
  });
}
