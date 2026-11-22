import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../widgets/common.dart';

/// Incoming bookings for a provider: accept, decline, mark completed.
class ProviderBookingsTab extends StatelessWidget {
  const ProviderBookingsTab({super.key, required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: SafeArea(
      child: StreamView<List<Booking>>(
        stream: () => context.backend.watchProviderBookings(provider.id),
        builder: (context, all) {
          final requests = all.where((b) => b.status == BookingStatus.pending).toList();
          final confirmed = all.where((b) => b.status == BookingStatus.accepted).toList();
          final past = all.where((b) => !b.isOpen).toList().reversed.toList();
          Widget list(List<Booking> items, String title, String message) => items.isEmpty
              ? EmptyState(icon: Icons.event_note_outlined, title: title, message: message)
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => ProviderBookingCard(booking: items[i]),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Bookings', style: context.text.displaySmall),
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Requests (${requests.length})'),
                  Tab(text: 'Confirmed (${confirmed.length})'),
                  const Tab(text: 'Past'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    list(
                      requests,
                      'No new requests',
                      'When a couple asks for a date, you can accept or decline it here.',
                    ),
                    list(confirmed, 'No confirmed bookings', 'Accepted requests move here until the event is done.'),
                    list(past, 'No past bookings', 'Completed, declined and cancelled bookings appear here.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class ProviderBookingCard extends StatelessWidget {
  const ProviderBookingCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final actions = context.actions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.coupleName, style: context.text.titleMedium),
                      const SizedBox(height: 2),
                      Text(b.serviceTitle, style: context.text.bodySmall),
                    ],
                  ),
                ),
                BookingStatusPill(b.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Info(Icons.event_outlined, fmtDateLong(b.eventDate)),
                if (b.guestCount != null) _Info(Icons.groups_outlined, '${b.guestCount} guests'),
                _Info(Icons.sell_outlined, money(b.amount)),
                if (b.status != BookingStatus.pending)
                  _Info(Icons.payments_outlined, '${b.paymentStatus.label} (${money(b.amountPaid)})'),
              ],
            ),
            if (b.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.colors.cardHigh, borderRadius: BorderRadius.circular(12)),
                child: Text('"${b.note}"', style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              ),
            ],
            if (b.status == BookingStatus.pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AsyncButton(
                      outlined: true,
                      label: 'Decline',
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          title: 'Decline this request?',
                          message: '${b.coupleName} will be told the date is not available.',
                          action: 'Decline',
                          destructive: true,
                        );
                        if (ok && context.mounted) {
                          await runGuarded(
                            context,
                            () => actions.respond(b, accept: false),
                            success: 'Request declined',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AsyncButton(
                      label: 'Accept',
                      icon: Icons.check,
                      onPressed: () => runGuarded(
                        context,
                        () => actions.respond(b, accept: true),
                        success: 'Booking confirmed. ${fmtDate(b.eventDate)} is now blocked on your calendar.',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (b.status == BookingStatus.accepted) ...[
              const SizedBox(height: 14),
              AsyncButton(
                outlined: true,
                label: 'Mark as completed',
                icon: Icons.task_alt,
                onPressed: () => runGuarded(context, () => actions.complete(b), success: 'Marked as completed'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.colors.muted),
      const SizedBox(width: 5),
      Flexible(child: Text(text, style: context.text.bodyMedium)),
    ],
  );
}
