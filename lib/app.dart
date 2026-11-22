import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/models/app_user.dart';
import 'data/models/notification.dart';
import 'data/repositories/repositories.dart';
import 'logic/booking_actions.dart';
import 'logic/session.dart';
import 'ui/admin/admin_shell.dart';
import 'ui/auth/welcome_screen.dart';
import 'ui/couple/couple_shell.dart';
import 'ui/provider/provider_shell.dart';
import 'ui/widgets/common.dart';

/// Whether the app runs on sample data. Read with `context.read<DemoMode>()`.
class DemoMode {
  const DemoMode(this.enabled);
  final bool enabled;
}

class DawatApp extends StatelessWidget {
  const DawatApp({super.key, required this.backend, required this.settings, this.isDemo = true});

  final Backend backend;
  final AppSettings settings;
  final bool isDemo;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<Backend>.value(value: backend),
      Provider<DemoMode>.value(value: DemoMode(isDemo)),
      Provider<BookingActions>(create: (_) => BookingActions(backend)),
      ChangeNotifierProvider<Session>(create: (_) => Session(backend)),
      ChangeNotifierProvider<AppSettings>.value(value: settings),
    ],
    child: Consumer<AppSettings>(
      builder: (context, s, _) => MaterialApp(
        title: 'Dawat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: s.themeMode,
        home: const RootGate(),
      ),
    ),
  );
}

/// Sends each actor to their own part of the app (use case diagram, §7.1).
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (!session.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = session.user;
    final Widget page = switch (user) {
      null => const WelcomeScreen(),
      Admin() => const AdminShell(),
      Couple() => _MaintenanceGuard(child: CoupleShell(key: ValueKey(user.id))),
      ServiceProvider() => _MaintenanceGuard(child: ProviderShell(key: ValueKey(user.id))),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: page);
  }
}

/// Shows a notice instead of the app while an admin has maintenance mode on.
class _MaintenanceGuard extends StatelessWidget {
  const _MaintenanceGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => StreamView<SystemSettings>(
    stream: () => context.backend.watchSettings(),
    builder: (context, settings) {
      if (!settings.maintenanceMode) return child;
      return Scaffold(
        body: EmptyState(
          icon: Icons.construction_outlined,
          title: 'Dawat is under maintenance',
          message: 'We are making improvements. Please check back soon.',
          action: 'Sign out',
          onAction: () => context.backend.signOut(),
        ),
      );
    },
  );
}
