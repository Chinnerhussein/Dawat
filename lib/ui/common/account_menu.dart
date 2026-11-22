import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../logic/session.dart';
import '../widgets/common.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MenuItem {
  const MenuItem(this.icon, this.label, this.onTap, {this.trailing, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;
}

class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.items});
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final i in items) ...[
          ListTile(
            leading: Icon(i.icon, color: i.color ?? context.scheme.primary),
            title: Text(i.label, style: context.text.titleSmall?.copyWith(color: i.color)),
            trailing: i.trailing ?? Icon(Icons.chevron_right, color: context.colors.muted),
            onTap: i.onTap,
          ),
          if (i != items.last) const Divider(indent: 56),
        ],
      ],
    ),
  );
}

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.user, required this.subtitle});
  final AppUser user;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final name = switch (user) {
      Couple(:final displayNames) => displayNames,
      ServiceProvider(:final businessName) => businessName,
      Admin(:final name) => name,
    };
    return HennaHero(
      radius: 18,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: context.colors.glow.withValues(alpha: 0.35),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(color: heroInk, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.titleLarge?.copyWith(color: heroInk)),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall?.copyWith(color: heroMuted)),
                Text(user.email, style: context.text.bodySmall?.copyWith(color: heroMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile, notifications, appearance, privacy and sign-out, shared by all
/// three actors.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, this.showNotifications = true});
  final bool showNotifications;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final demo = context.read<DemoMode>().enabled;
    return Column(
      children: [
        MenuCard(
          items: [
            MenuItem(
              Icons.person_outline,
              'Profile',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            if (showNotifications)
              MenuItem(
                Icons.notifications_none,
                'Notifications',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
            MenuItem(
              settings.themeMode == ThemeMode.light ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              'Appearance',
              () => _pickTheme(context, settings),
              trailing: Text(switch (settings.themeMode) {
                ThemeMode.dark => 'Henna Night',
                ThemeMode.light => 'Light',
                ThemeMode.system => 'Match phone',
              }, style: context.text.bodySmall),
            ),
            MenuItem(Icons.shield_outlined, 'Privacy & your data', () => _privacy(context)),
          ],
        ),
        const SizedBox(height: 16),
        MenuCard(
          items: [
            MenuItem(
              Icons.logout,
              'Sign out',
              () => context.backend.signOut(),
              color: context.colors.danger,
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(demo ? 'Dawat · demo mode, sample data' : 'Dawat', style: context.text.bodySmall),
      ],
    );
  }

  void _pickTheme(BuildContext context, AppSettings settings) => showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: RadioGroup<ThemeMode>(
        groupValue: settings.themeMode,
        onChanged: (m) {
          if (m != null) settings.setThemeMode(m);
          Navigator.pop(ctx);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Appearance', style: ctx.text.headlineSmall),
            const SizedBox(height: 8),
            const RadioListTile(value: ThemeMode.dark, title: Text('Henna Night (dark)')),
            const RadioListTile(value: ThemeMode.light, title: Text('Light')),
            const RadioListTile(value: ThemeMode.system, title: Text('Match my phone')),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );

  void _privacy(BuildContext context) {
    final user = context.read<Session>().user;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Privacy & your data', style: ctx.text.headlineSmall),
        content: Text(
          'Dawat stores only what it needs for wedding planning: your account details'
          '${user is Couple
              ? ', bookings, guest list, budget and checklist'
              : user is ServiceProvider
              ? ', business profile, services and bookings'
              : ''}.\n\n'
          'Providers see only the bookings made with them. Admins can see accounts to keep the service safe.\n\n'
          'You can edit your details under Profile. To delete your account and all its data, '
          'contact the Dawat team from your registered email (${roleName(user?.role ?? UserRole.couple)} account).',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
