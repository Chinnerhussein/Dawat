import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo/demo_seed.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = context.read<DemoMode>().enabled;
    return Scaffold(
      body: HennaHero(
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const DawatLogo(size: 44),
                        const SizedBox(height: 6),
                        Text(
                          'Wedding planning for Kurdistan',
                          style: context.text.bodyMedium?.copyWith(color: heroMuted),
                        ),
                        const SizedBox(height: 56),
                        Text(
                          'Plan your\nperfect day',
                          style: context.text.displayMedium?.copyWith(color: heroInk, fontSize: 42),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Find halls, caterers, photographers and salons, check prices and free dates, '
                          'and keep your guests, budget and checklist in one place.',
                          style: context.text.bodyLarge?.copyWith(color: heroMuted),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Create an account'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: heroInk,
                              side: BorderSide(color: heroInk.withValues(alpha: 0.4)),
                            ),
                            onPressed: () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: const Text('Sign in'),
                          ),
                        ),
                        if (demo) ...[const SizedBox(height: 32), const _DemoAccounts()],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-tap sign-in for each actor, shown only in demo mode.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) {
    Widget account(String label, String sub, IconData icon, (String, String) creds) => Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => runGuarded(context, () => context.backend.signIn(creds.$1, creds.$2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: context.colors.glow),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: heroInk, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: heroMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEMO MODE · TRY AS', style: context.text.labelSmall?.copyWith(color: heroMuted, letterSpacing: 1.4)),
        const SizedBox(height: 10),
        Row(
          children: [
            account('Bride & Groom', 'Shno & Aram', Icons.favorite_border, DemoAccounts.couple),
            const SizedBox(width: 10),
            account('Provider', 'Lalav Hall', Icons.storefront_outlined, DemoAccounts.provider),
            const SizedBox(width: 10),
            account('Admin', 'Dawat team', Icons.admin_panel_settings_outlined, DemoAccounts.admin),
          ],
        ),
      ],
    );
  }
}
