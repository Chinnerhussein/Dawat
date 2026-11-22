import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/notification.dart';
import '../../data/models/service.dart';
import '../../logic/session.dart';
import '../common/account_menu.dart';
import '../widgets/common.dart';

/// Admin area: "Manage Users, Providers & System Settings".
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Session>().user;
    if (admin is! Admin) return const SizedBox.shrink();
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _Overview(openTab: (i) => setState(() => _index = i)),
          _UsersTab(admin: admin),
          const _ProvidersTab(),
          _SettingsTab(admin: admin),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Overview',
          ),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Providers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.openTab});
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return StreamView<List<AppUser>>(
      stream: backend.watchUsers,
      builder: (context, users) => StreamView<List<Booking>>(
        stream: backend.watchAllBookings,
        builder: (context, bookings) => StreamView<List<Service>>(
          stream: () => backend.watchServices(),
          builder: (context, services) {
            final couples = users.whereType<Couple>().length;
            final providers = users.whereType<ServiceProvider>().toList();
            final pending = providers.where((p) => p.approval == ApprovalStatus.pending).length;
            final suspended = users.where((u) => !u.isActive).length;
            final value = bookings
                .where((b) => b.status == BookingStatus.accepted || b.status == BookingStatus.completed)
                .fold<double>(0, (a, b) => a + b.amount);
            final c = context.colors;
            final recent = [...users]
              ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
            final byStatus = {for (final s in BookingStatus.values) s: bookings.where((b) => b.status == s).length};

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HennaHero(
                    padding: EdgeInsets.zero,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const DawatLogo(size: 26),
                                const SizedBox(width: 8),
                                Text('admin', style: context.text.bodySmall?.copyWith(color: heroMuted)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('Booking value confirmed', style: context.text.bodyMedium?.copyWith(color: heroMuted)),
                            Text(
                              money(value),
                              style: context.text.displayMedium?.copyWith(color: heroInk, fontStyle: FontStyle.normal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${bookings.length} bookings · ${services.length} services listed',
                              style: context.text.bodySmall?.copyWith(color: heroMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: StatGrid(
                      children: [
                        StatTile(
                          label: 'Couples',
                          value: '$couples',
                          icon: Icons.favorite_border,
                          onTap: () => openTab(1),
                        ),
                        StatTile(
                          label: 'Providers',
                          value: '${providers.length}',
                          icon: Icons.storefront_outlined,
                          color: c.roseGold,
                          onTap: () => openTab(2),
                        ),
                        StatTile(
                          label: 'Awaiting approval',
                          value: '$pending',
                          icon: Icons.hourglass_top,
                          color: c.warning,
                          onTap: () => openTab(2),
                        ),
                        StatTile(
                          label: 'Suspended accounts',
                          value: '$suspended',
                          icon: Icons.block,
                          color: c.danger,
                          onTap: () => openTab(1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Bookings by status')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final s in BookingStatus.values) ...[
                              Row(
                                children: [
                                  SizedBox(width: 96, child: Text(s.label, style: context.text.bodyMedium)),
                                  Expanded(
                                    child: LabeledBar(
                                      value: bookings.isEmpty ? 0 : byStatus[s]! / bookings.length,
                                      color: bookingColor(context, s),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${byStatus[s]}',
                                      textAlign: TextAlign.end,
                                      style: context.text.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                              if (s != BookingStatus.values.last) const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Newest accounts')),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: recent.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _UserRow(user: recent[i]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, this.trailing});
  final AppUser user;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final title = u is ServiceProvider ? u.businessName : (u is Couple ? u.displayNames : u.name);
    final color = switch (u.role) {
      UserRole.couple => context.colors.roseGold,
      UserRole.provider => context.colors.info,
      UserRole.admin => context.colors.success,
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Text(
            title.isEmpty ? '?' : title[0],
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          title,
          style: context.text.titleSmall?.copyWith(decoration: u.isActive ? null : TextDecoration.lineThrough),
        ),
        subtitle: Text('${roleName(u.role)} · ${cityName(u.city)}\n${u.email}'),
        isThreeLine: true,
        trailing: trailing,
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.admin});
  final Admin admin;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  UserRole? _role;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamView<List<AppUser>>(
      stream: context.backend.watchUsers,
      builder: (context, users) {
        final q = _search.text.trim().toLowerCase();
        final shown = users.where((u) {
          if (_role != null && u.role != _role) return false;
          if (q.isEmpty) return true;
          final extra = u is ServiceProvider ? u.businessName : (u is Couple ? u.partnerName : '');
          return '${u.name} $extra ${u.email}'.toLowerCase().contains(q);
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Users', style: context.text.displaySmall),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Search by name or email', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('All (${users.length})'),
                  selected: _role == null,
                  onSelected: (_) => setState(() => _role = null),
                ),
                for (final r in UserRole.values)
                  ChoiceChip(
                    label: Text('${roleName(r)} (${users.where((u) => u.role == r).length})'),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final u in shown) ...[
              _UserRow(
                user: u,
                trailing: u.id == widget.admin.id
                    ? Text('You', style: context.text.bodySmall)
                    : Switch(
                        value: u.isActive,
                        onChanged: (v) async {
                          if (!v) {
                            final ok = await confirm(
                              context,
                              title: 'Suspend this account?',
                              message: '${u.email} will be signed out and cannot sign in until you reactivate it.',
                              action: 'Suspend',
                              destructive: true,
                            );
                            if (!ok || !context.mounted) return;
                          }
                          await runGuarded(
                            context,
                            () => context.backend.setUserActive(u.id, v),
                            success: v ? 'Account reactivated' : 'Account suspended',
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
            if (shown.isEmpty)
              const EmptyState(
                icon: Icons.person_search,
                title: 'No users match',
                message: 'Try another search or role.',
              ),
          ],
        );
      },
    ),
  );
}

class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab();

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return SafeArea(
      child: StreamView<List<ServiceProvider>>(
        stream: backend.watchProviders,
        builder: (context, providers) => StreamView<List<Service>>(
          stream: () => backend.watchServices(),
          builder: (context, services) {
            final pending = providers.where((p) => p.approval == ApprovalStatus.pending).toList();
            final approved = providers.where((p) => p.approval == ApprovalStatus.approved).toList();
            final rejected = providers.where((p) => p.approval == ApprovalStatus.rejected).toList();
            int count(ServiceProvider p) => services.where((s) => s.providerId == p.id).length;

            Widget card(ServiceProvider p, {required bool showActions}) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.businessName, style: context.text.titleMedium),
                              Text(
                                '${p.name} · ${cityName(p.city)} · ${count(p)} services',
                                style: context.text.bodySmall,
                              ),
                              Text(p.email, style: context.text.bodySmall),
                            ],
                          ),
                        ),
                        if (!showActions)
                          StatusPill(
                            p.approval == ApprovalStatus.approved ? 'Approved' : 'Rejected',
                            color: p.approval == ApprovalStatus.approved
                                ? context.colors.success
                                : context.colors.danger,
                          ),
                      ],
                    ),
                    if (p.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text('Joined ${fmtDate(p.createdAt!)}', style: context.text.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (showActions || p.approval == ApprovalStatus.approved)
                          Expanded(
                            child: AsyncButton(
                              outlined: true,
                              label: showActions ? 'Reject' : 'Revoke approval',
                              onPressed: () => runGuarded(
                                context,
                                () => context.actions.setProviderApproval(p, ApprovalStatus.rejected),
                                success: '${p.businessName} rejected',
                              ),
                            ),
                          ),
                        if (showActions) const SizedBox(width: 10),
                        if (showActions || p.approval == ApprovalStatus.rejected)
                          Expanded(
                            child: AsyncButton(
                              label: 'Approve',
                              icon: Icons.verified_outlined,
                              onPressed: () => runGuarded(
                                context,
                                () => context.actions.setProviderApproval(p, ApprovalStatus.approved),
                                success: '${p.businessName} is now visible to couples',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text('Providers', style: context.text.displaySmall),
                const SizedBox(height: 6),
                Text('New businesses stay hidden from couples until you approve them.', style: context.text.bodySmall),
                SectionHeaderPadless('Waiting for review (${pending.length})'),
                if (pending.isEmpty) Text('Nothing to review.', style: context.text.bodyMedium),
                for (final p in pending) ...[card(p, showActions: true), const SizedBox(height: 10)],
                SectionHeaderPadless('Approved (${approved.length})'),
                for (final p in approved) ...[card(p, showActions: false), const SizedBox(height: 10)],
                if (rejected.isNotEmpty) ...[
                  SectionHeaderPadless('Rejected (${rejected.length})'),
                  for (final p in rejected) ...[card(p, showActions: false), const SizedBox(height: 10)],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class SectionHeaderPadless extends StatelessWidget {
  const SectionHeaderPadless(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(title, style: context.text.headlineSmall),
  );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.admin});
  final Admin admin;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return SafeArea(
      child: StreamView<SystemSettings>(
        stream: backend.watchSettings,
        builder: (context, s) {
          Future<void> save(SystemSettings next, String message) =>
              runGuarded(context, () => backend.saveSettings(next), success: message);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('System settings', style: context.text.displaySmall),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Allow provider sign-up'),
                      subtitle: const Text('New businesses can create accounts in the app.'),
                      value: s.allowProviderSignup,
                      onChanged: (v) => save(
                        s.copyWith(allowProviderSignup: v),
                        v ? 'Provider sign-up opened' : 'Provider sign-up closed',
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Review new providers'),
                      subtitle: const Text('New businesses stay hidden until an admin approves them.'),
                      value: s.requireProviderApproval,
                      onChanged: (v) => save(s.copyWith(requireProviderApproval: v), 'Setting saved'),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Maintenance mode'),
                      subtitle: const Text('Couples and providers see a maintenance notice. Admins can still sign in.'),
                      value: s.maintenanceMode,
                      onChanged: (v) async {
                        if (v) {
                          final ok = await confirm(
                            context,
                            title: 'Turn on maintenance mode?',
                            message: 'Couples and providers will not be able to use Dawat until you turn it off.',
                            action: 'Turn on',
                            destructive: true,
                          );
                          if (!ok || !context.mounted) return;
                        }
                        await save(s.copyWith(maintenanceMode: v), v ? 'Maintenance mode on' : 'Maintenance mode off');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Cities offered at sign-up', style: context.text.headlineSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in kCities)
                    FilterChip(
                      label: Text(cityName(c)),
                      selected: s.enabledCities.contains(c),
                      onSelected: (on) {
                        final next = on ? [...s.enabledCities, c] : s.enabledCities.where((x) => x != c).toList();
                        if (next.isEmpty) {
                          toast(context, 'Keep at least one city.');
                          return;
                        }
                        save(
                          s.copyWith(
                            enabledCities: [
                              for (final k in kCities)
                                if (next.contains(k)) k,
                            ],
                          ),
                          'Cities updated',
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              AccountHeader(user: admin, subtitle: 'Administrator'),
              const SizedBox(height: 16),
              const AccountMenu(showNotifications: false),
            ],
          );
        },
      ),
    );
  }
}
