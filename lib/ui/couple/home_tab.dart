import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/planner.dart';
import '../../data/models/service.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../widgets/common.dart';
import 'bookings_screen.dart';
import 'catalog.dart';
import 'couple_shell.dart';
import 'guests_screen.dart';
import 'service_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final shell = CoupleShell.of(context);
    return CatalogView(
      userId: couple.id,
      builder: (context, catalog) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(couple: couple)),
          SliverToBoxAdapter(child: _PlanningSnapshot(couple: couple)),
          const SliverToBoxAdapter(child: SectionHeader('Find services')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [
                for (final c in ServiceCategory.values.where((c) => c != ServiceCategory.other))
                  _CategoryTile(
                    category: c,
                    onTap: () => shell.openVendors(category: c),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _NextBooking(couple: couple)),
          SliverToBoxAdapter(
            child: SectionHeader('Top rated vendors', action: 'See all', onAction: () => shell.openVendors()),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 232,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: catalog.services.take(8).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = catalog.services[i];
                  return ServiceCard(
                    service: s,
                    isFavorite: catalog.isFavorite(s),
                    onFavorite: () => toggleFavorite(context, couple.id, s, catalog.isFavorite(s)),
                    onTap: () => openService(context, s.id),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final days = couple.daysToGo;
    final date = couple.weddingDate;
    return HennaHero(
      padding: EdgeInsets.zero,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DawatLogo(size: 30),
                  const Spacer(),
                  NotificationBell(
                    userId: couple.id,
                    color: heroInk,
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  IconButton(
                    tooltip: 'Profile',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: context.colors.glow.withValues(alpha: 0.35),
                      child: Text(
                        couple.name.isEmpty ? '?' : couple.name[0].toUpperCase(),
                        style: const TextStyle(color: heroInk, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                couple.displayNames,
                style: context.text.titleMedium?.copyWith(color: heroMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              if (days != null && days >= 0 && date != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$days', style: context.text.displayLarge?.copyWith(color: heroInk, fontSize: 56, height: 1)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        days == 1 ? 'day to go' : 'days to go',
                        style: context.text.headlineSmall?.copyWith(color: heroInk, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(fmtDateLong(date), style: context.text.bodyMedium?.copyWith(color: heroMuted)),
              ] else ...[
                Text('Plan your perfect day', style: context.text.displaySmall?.copyWith(color: heroInk)),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: context.colors.glow),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: const Text('Set your wedding date'),
                ),
              ],
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => CoupleShell.of(context).openVendors(focusSearch: true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: heroMuted, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search halls, photographers, salons…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: heroMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checklist, budget and guest progress at a glance.
class _PlanningSnapshot extends StatelessWidget {
  const _PlanningSnapshot({required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    final shell = CoupleShell.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: StreamView<List<ChecklistTask>>(
        stream: () => backend.watchTasks(couple.id),
        loading: const SizedBox(height: 110),
        builder: (context, tasks) => StreamView<List<BudgetExpense>>(
          stream: () => backend.watchExpenses(couple.id),
          loading: const SizedBox(height: 110),
          builder: (context, expenses) => StreamView<List<Guest>>(
            stream: () => backend.watchGuests(couple.id),
            loading: const SizedBox(height: 110),
            builder: (context, guests) {
              final done = tasks.where((t) => t.done).length;
              final spent = expenses.fold<double>(0, (a, e) => a + e.amount);
              final attending = guests
                  .where((g) => g.rsvpStatus == RsvpStatus.attending)
                  .fold<int>(0, (a, g) => a + g.partySize);
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Tasks done',
                        value: '$done/${tasks.length}',
                        icon: Icons.checklist,
                        onTap: () => shell.openTab(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: couple.totalBudget > 0 ? 'of ${moneyCompact(couple.totalBudget)} spent' : 'Spent',
                        value: moneyCompact(spent),
                        icon: Icons.account_balance_wallet_outlined,
                        color: context.colors.roseGold,
                        onTap: () => shell.openTab(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Guests coming',
                        value: '$attending',
                        icon: Icons.people_outline,
                        color: context.colors.success,
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GuestsScreen(couple: couple))),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, color: context.scheme.primary, size: 26),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(fontSize: 11, letterSpacing: 0.1),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The couple's most urgent booking: one awaiting payment, else the next
/// pending request.
class _NextBooking extends StatelessWidget {
  const _NextBooking({required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) => StreamView<List<Booking>>(
    stream: () => context.backend.watchCoupleBookings(couple.id),
    loading: const SizedBox.shrink(),
    builder: (context, bookings) {
      final open = bookings.where((b) => b.isOpen).toList();
      if (open.isEmpty) return const SizedBox.shrink();
      final payable = open.where((b) => b.canPay).toList();
      final b = payable.isNotEmpty ? payable.first : open.first;
      final c = context.colors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Your bookings',
            action: 'View all (${open.length})',
            onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingsScreen(couple: couple))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingsScreen(couple: couple))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: c.pillBg, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Text(
                              '${b.eventDate.day}',
                              style: context.text.headlineMedium?.copyWith(
                                fontStyle: FontStyle.normal,
                                color: c.roseGold,
                                height: 1,
                              ),
                            ),
                            Text(
                              fmtDateShort(b.eventDate).split(' ').last.toUpperCase(),
                              style: context.text.labelSmall?.copyWith(color: c.roseGold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.serviceTitle, style: context.text.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              b.canPay
                                  ? (b.amountPaid == 0
                                        ? 'Pay the ${money(b.depositAmount)} deposit to lock it in'
                                        : '${money(b.balanceDue)} balance left')
                                  : 'Waiting for the vendor to reply',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      BookingStatusPill(b.status),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

void openService(BuildContext context, String serviceId) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: serviceId)));
