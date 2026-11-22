import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/service.dart';
import '../../logic/booking_actions.dart';
import '../../logic/session.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import 'bookings_screen.dart';

/// "View Prices & Availability" use case, and the entry to booking.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});
  final String serviceId;

  @override
  Widget build(BuildContext context) {
    final couple = context.watch<Session>().user;
    final backend = context.backend;
    return StreamView<List<Service>>(
      stream: () => backend.watchServices(),
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      builder: (context, services) {
        final s = services.where((x) => x.id == serviceId).firstOrNull;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'Listing removed',
              message: 'This vendor no longer offers this service.',
            ),
          );
        }
        return StreamView<List<ServiceProvider>>(
          stream: backend.watchProviders,
          builder: (context, providers) {
            final provider = providers.where((p) => p.id == s.providerId).firstOrNull;
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    foregroundColor: heroInk,
                    backgroundColor: s.category.artColors.last,
                    actions: [
                      if (couple is Couple)
                        StreamView<Set<String>>(
                          stream: () => backend.watchWishlist(couple.id),
                          loading: const SizedBox.shrink(),
                          builder: (context, favs) {
                            final fav = favs.contains(s.id);
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FavoriteButton(
                                isFavorite: fav,
                                onPressed: () => runGuarded(
                                  context,
                                  () => backend.setFavorite(couple.id, s.id, !fav),
                                  success: fav ? 'Removed from favorites' : 'Saved to favorites',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: ServiceArt(category: s.category, height: 300, radius: 0, iconSize: 64),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.category.label.toUpperCase(),
                            style: context.text.labelSmall?.copyWith(
                              color: context.colors.roseGold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(s.title, style: context.text.displaySmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RatingText(rating: s.rating, count: s.ratingCount),
                              _Meta(icon: Icons.place_outlined, text: cityName(s.city)),
                              if (s.capacity != null)
                                _Meta(icon: Icons.groups_outlined, text: 'Up to ${s.capacity} guests'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _PriceCard(service: s),
                          if (s.description.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            Text('About', style: context.text.headlineSmall),
                            const SizedBox(height: 8),
                            Text(s.description, style: context.text.bodyLarge),
                          ],
                          const SizedBox(height: 22),
                          Text('Availability', style: context.text.headlineSmall),
                          const SizedBox(height: 10),
                          _AvailabilityCard(service: s, couple: couple is Couple ? couple : null),
                          if (provider != null) ...[
                            const SizedBox(height: 22),
                            Text('Provider', style: context.text.headlineSmall),
                            const SizedBox(height: 10),
                            _ProviderCard(provider: provider),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: couple is Couple ? _BookBar(service: s, couple: couple) : null,
            );
          },
        );
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.colors.muted),
      const SizedBox(width: 4),
      Text(text, style: context.text.bodySmall),
    ],
  );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: context.colors.pillBg, borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price', style: context.text.bodySmall),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: money(service.price),
                      style: context.text.headlineMedium?.copyWith(
                        fontStyle: FontStyle.normal,
                        color: context.colors.roseGold,
                      ),
                    ),
                    TextSpan(text: service.priceUnit.suffix, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Deposit to confirm', style: context.text.bodySmall),
            const SizedBox(height: 2),
            Text('${(Booking.depositRate * 100).round()}%', style: context.text.titleMedium),
          ],
        ),
      ],
    ),
  );
}

class _AvailabilityCard extends StatefulWidget {
  const _AvailabilityCard({required this.service, this.couple});
  final Service service;
  final Couple? couple;

  @override
  State<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<_AvailabilityCard> {
  DateTime? _checked;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final wedding = widget.couple?.weddingDate;
    Widget row(String label, DateTime d) {
      final free = s.checkAvailability(d);
      return Row(
        children: [
          Icon(
            free ? Icons.event_available : Icons.event_busy,
            color: free ? context.colors.success : context.colors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(fmtDateLong(d), style: context.text.titleSmall),
              ],
            ),
          ),
          StatusPill(free ? 'Available' : 'Booked', color: free ? context.colors.success : context.colors.danger),
        ],
      );
    }

    final upcomingBlocked = s.blockedDates.where((d) => d.isAfter(DateTime.now())).toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wedding != null) ...[row('Your wedding day', wedding), const SizedBox(height: 14)],
            if (_checked != null) ...[row('Date you checked', _checked!), const SizedBox(height: 14)],
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _checked ?? wedding ?? now.add(const Duration(days: 30)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 3),
                  helpText: 'Check a date',
                );
                if (d != null) setState(() => _checked = d);
              },
              icon: const Icon(Icons.search),
              label: const Text('Check another date'),
            ),
            if (upcomingBlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Already booked', style: context.text.bodySmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in upcomingBlocked.take(8)) StatusPill(fmtDateShort(d), color: context.colors.muted),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.scheme.primary.withValues(alpha: 0.18),
                child: Text(
                  provider.businessName[0],
                  style: TextStyle(color: context.scheme.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.businessName, style: context.text.titleSmall),
                    Text('${cityName(provider.city)} · Verified by Dawat', style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.verified, color: context.colors.success, size: 20),
            ],
          ),
          if (provider.bio.isNotEmpty) ...[const SizedBox(height: 12), Text(provider.bio)],
          if (provider.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: context.colors.muted),
                const SizedBox(width: 8),
                SelectableText(provider.phone),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.service, required this.couple});
  final Service service;
  final Couple couple;

  @override
  Widget build(BuildContext context) => StreamView<List<Booking>>(
    stream: () => context.backend.watchCoupleBookings(couple.id),
    loading: const SizedBox.shrink(),
    builder: (context, bookings) {
      final existing = bookings.where((b) => b.serviceId == service.id && b.isOpen).firstOrNull;
      return Container(
        decoration: BoxDecoration(
          color: context.scheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: context.colors.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: existing != null
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('You booked this for', style: context.text.bodySmall),
                            Text(fmtDate(existing.eventDate), style: context.text.titleSmall),
                          ],
                        ),
                      ),
                      BookingStatusPill(existing.status),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BookingsScreen(couple: couple))),
                        child: const Text('View'),
                      ),
                    ],
                  )
                : FilledButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BookingRequestSheet(service: service, couple: couple),
                    ),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Request a booking'),
                  ),
          ),
        ),
      );
    },
  );
}

/// "Book Services" use case: choose a free date and send a request.
class BookingRequestSheet extends StatefulWidget {
  const BookingRequestSheet({super.key, required this.service, required this.couple});
  final Service service;
  final Couple couple;

  @override
  State<BookingRequestSheet> createState() => _BookingRequestSheetState();
}

class _BookingRequestSheetState extends State<BookingRequestSheet> {
  final _form = GlobalKey<FormState>();
  late DateTime? _date = _initialDate();
  final _guests = TextEditingController();
  final _note = TextEditingController();

  DateTime? _initialDate() {
    final w = widget.couple.weddingDate;
    return (w != null && w.isAfter(DateTime.now()) && widget.service.checkAvailability(w)) ? w : null;
  }

  @override
  void dispose() {
    _guests.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _guestCount => int.tryParse(_guests.text.trim());

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(context, () async {
      await context.actions.requestBooking(
        couple: widget.couple,
        service: widget.service,
        date: _date!,
        guestCount: _guestCount,
        note: _note.text,
      );
    }, success: 'Request sent. ${widget.service.providerName} will reply soon.');
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final perPerson = s.priceUnit == PriceUnit.perPerson;
    final total = BookingActions.quote(s, _guestCount);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Request ${s.title}', style: context.text.headlineMedium),
                const SizedBox(height: 4),
                Text('Booked dates are greyed out in the calendar.', style: context.text.bodySmall),
                const SizedBox(height: 18),
                DateField(
                  label: 'Event date',
                  value: _date,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  selectable: s.checkAvailability,
                  onChanged: (d) => setState(() => _date = d),
                  validator: (d) => d == null ? 'Choose a date.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _guests,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: perPerson ? 'Number of guests' : 'Number of guests (optional)',
                    prefixIcon: const Icon(Icons.groups_outlined),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if ((v ?? '').trim().isEmpty) return perPerson ? 'Enter the number of guests.' : null;
                    if (n == null || n <= 0) return 'Enter a whole number.';
                    if (s.capacity != null && n > s.capacity!) return 'This venue holds up to ${s.capacity} guests.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Message to the vendor (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: context.colors.pillBg, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _Line(
                        'Estimated total',
                        perPerson && _guestCount == null ? '${money(s.price)} / person' : money(total),
                        bold: true,
                      ),
                      const SizedBox(height: 6),
                      _Line('Deposit after the vendor confirms', money((total * Booking.depositRate).roundToDouble())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AsyncButton(label: 'Send request', icon: Icons.send_outlined, onPressed: _submit),
                const SizedBox(height: 8),
                Text(
                  'You pay nothing now. The vendor accepts or declines your request first.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: bold ? context.text.titleSmall : context.text.bodyMedium)),
      Text(
        value,
        style: (bold ? context.text.titleMedium : context.text.bodyMedium)?.copyWith(
          color: bold ? context.colors.roseGold : null,
        ),
      ),
    ],
  );
}
