import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/service.dart';
import '../../logic/session.dart';
import '../common/account_menu.dart';
import '../common/notifications_screen.dart';
import '../widgets/common.dart';
import 'provider_bookings.dart';
import 'service_editor.dart';

/// Service Provider area: "Manage Services, Pricing & Incoming Bookings".
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    if (user is! ServiceProvider) return const SizedBox.shrink();
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _Dashboard(provider: user, openTab: (i) => setState(() => _index = i)),
          _ServicesTab(provider: user),
          ProviderBookingsTab(provider: user),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text('More', style: context.text.displaySmall),
                const SizedBox(height: 16),
                AccountHeader(user: user, subtitle: '${cityName(user.city)} · ${_approvalLabel(user.approval)}'),
                const SizedBox(height: 16),
                const AccountMenu(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Bookings',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

String _approvalLabel(ApprovalStatus a) => switch (a) {
  ApprovalStatus.approved => 'Verified',
  ApprovalStatus.pending => 'Waiting for approval',
  ApprovalStatus.rejected => 'Not approved',
};

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.provider, required this.openTab});
  final ServiceProvider provider;
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return StreamView<List<Booking>>(
      stream: () => backend.watchProviderBookings(provider.id),
      builder: (context, bookings) => StreamView<List<Service>>(
        stream: () => backend.watchServices(providerId: provider.id),
        builder: (context, services) {
          final now = DateTime.now();
          final requests = bookings.where((b) => b.status == BookingStatus.pending).toList();
          final upcoming = bookings
              .where(
                (b) =>
                    b.status == BookingStatus.accepted && !b.eventDate.isBefore(DateTime(now.year, now.month, now.day)),
              )
              .toList();
          final received = bookings.fold<double>(0, (a, b) => a + b.amountPaid);
          final c = context.colors;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HennaHero(
                  padding: EdgeInsets.zero,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const DawatLogo(size: 26),
                              const SizedBox(width: 8),
                              Text('for business', style: context.text.bodySmall?.copyWith(color: heroMuted)),
                              const Spacer(),
                              NotificationBell(
                                userId: provider.id,
                                color: heroInk,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(provider.businessName, style: context.text.displaySmall?.copyWith(color: heroInk)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                provider.approval == ApprovalStatus.approved ? Icons.verified : Icons.hourglass_top,
                                size: 16,
                                color: c.glow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_approvalLabel(provider.approval)} · ${cityName(provider.city)}',
                                style: context.text.bodyMedium?.copyWith(color: heroMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.approval != ApprovalStatus.approved)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Card(
                      color: c.pillBg,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: c.roseGold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.approval == ApprovalStatus.pending
                                    ? 'Couples cannot see your services yet. The Dawat team reviews new businesses, usually within two working days. You can add your services now.'
                                    : 'Your business was not approved, so couples cannot see your services. Contact Dawat support for details.',
                                style: context.text.bodyMedium,
                              ),
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
                        label: 'New requests',
                        value: '${requests.length}',
                        icon: Icons.mark_email_unread_outlined,
                        color: c.warning,
                        onTap: () => openTab(2),
                      ),
                      StatTile(
                        label: 'Upcoming events',
                        value: '${upcoming.length}',
                        icon: Icons.event_available_outlined,
                        color: c.success,
                        onTap: () => openTab(2),
                      ),
                      StatTile(
                        label: 'Payments received',
                        value: moneyCompact(received),
                        icon: Icons.payments_outlined,
                        color: c.roseGold,
                      ),
                      StatTile(
                        label: 'Active services',
                        value: '${services.where((s) => s.isActive).length}',
                        icon: Icons.storefront_outlined,
                        onTap: () => openTab(1),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Requests waiting',
                  action: requests.isEmpty ? null : 'See all',
                  onAction: () => openTab(2),
                ),
              ),
              if (requests.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'No new requests. They will appear here and in your notifications.',
                      style: context.text.bodySmall,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: requests.take(3).length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => ProviderBookingCard(booking: requests[i]),
                  ),
                ),
              if (upcoming.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeader('Coming up')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: upcoming.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final b = upcoming[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.event, color: context.scheme.primary),
                          title: Text(b.coupleName, style: context.text.titleSmall),
                          subtitle: Text('${b.serviceTitle} · ${fmtDate(b.eventDate)}'),
                          trailing: Text(b.paymentStatus.label, style: context.text.bodySmall),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          );
        },
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceEditorScreen(provider: provider))),
      icon: const Icon(Icons.add),
      label: const Text('New service'),
    ),
    body: SafeArea(
      child: StreamView<List<Service>>(
        stream: () => context.backend.watchServices(providerId: provider.id),
        builder: (context, services) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('My services', style: context.text.displaySmall),
            const SizedBox(height: 6),
            Text('Set prices, capacity and the dates you are not available.', style: context.text.bodySmall),
            const SizedBox(height: 16),
            if (services.isEmpty)
              EmptyState(
                icon: Icons.storefront_outlined,
                title: 'Add your first service',
                message: 'Couples find you through your services: a hall, a menu, a photo package…',
                action: 'New service',
                onAction: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceEditorScreen(provider: provider))),
              )
            else
              for (final s in services) ...[
                Opacity(
                  opacity: s.isActive ? 1 : 0.6,
                  child: ServiceTile(
                    service: s,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceEditorScreen(provider: provider, service: s),
                      ),
                    ),
                    trailing: s.isActive
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: StatusPill('Paused', color: context.colors.muted),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    ),
  );
}
