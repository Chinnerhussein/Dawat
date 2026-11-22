import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../logic/booking_actions.dart';
import '../widgets/common.dart';
import 'home_tab.dart';

/// The couple's bookings and their status (§6.4 "track booking status").
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: StreamView<List<Booking>>(
        stream: () => context.backend.watchCoupleBookings(couple.id),
        builder: (context, all) {
          final active = all.where((b) => b.isOpen).toList();
          final past = all.where((b) => !b.isOpen).toList().reversed.toList();
          Widget list(List<Booking> items, String emptyTitle, String emptyMessage) => items.isEmpty
              ? EmptyState(icon: Icons.event_note_outlined, title: emptyTitle, message: emptyMessage)
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => CoupleBookingCard(booking: items[i]),
                );
          return TabBarView(
            children: [
              list(active, 'No active bookings', 'Find a vendor and send a booking request. It will show up here.'),
              list(past, 'Nothing here yet', 'Completed, declined and cancelled bookings appear here.'),
            ],
          );
        },
      ),
    ),
  );
}

class CoupleBookingCard extends StatelessWidget {
  const CoupleBookingCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final c = context.colors;
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
                  child: InkWell(
                    onTap: () => openService(context, b.serviceId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.serviceTitle, style: context.text.titleMedium),
                        const SizedBox(height: 4),
                        Text(fmtDateLong(b.eventDate), style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ),
                BookingStatusPill(b.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Figure(label: 'Total', value: money(b.amount)),
                _Figure(label: 'Paid', value: money(b.amountPaid)),
                _Figure(label: 'Payment', value: b.paymentStatus.label),
              ],
            ),
            if (b.amount > 0) ...[
              const SizedBox(height: 10),
              LabeledBar(value: b.amountPaid / b.amount, color: c.success),
            ],
            if (b.status == BookingStatus.pending) ...[
              const SizedBox(height: 12),
              Text('Waiting for the vendor to accept. You will get a notification.', style: context.text.bodySmall),
            ],
            if (b.isOpen) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (b.canPay)
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(64, 46)),
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(booking: b))),
                        child: Text(b.amountPaid == 0 ? 'Pay deposit' : 'Pay balance'),
                      ),
                    ),
                  if (b.canPay) const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 46)),
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          title: 'Cancel this booking?',
                          message: b.amountPaid > 0
                              ? 'The vendor will be told and the date released. Refunds of the ${money(b.amountPaid)} you paid are agreed directly with the vendor.'
                              : 'The vendor will be told and the date released.',
                          action: 'Cancel booking',
                          destructive: true,
                        );
                        if (ok && context.mounted) {
                          await runGuarded(context, () => context.actions.cancel(b), success: 'Booking cancelled');
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: context.text.titleSmall),
      ],
    ),
  );
}

/// "Make Payment" use case. Payment-provider integration is planned
/// (report §9.3), so this is a test checkout: no money is charged.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _form = GlobalKey<FormState>();
  late PaymentOption _option = widget.booking.amountPaid == 0 ? PaymentOption.deposit : PaymentOption.balance;
  final _name = TextEditingController();
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _card, _expiry, _cvc]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amount => _option == PaymentOption.deposit ? widget.booking.depositAmount : widget.booking.balanceDue;

  Future<void> _pay() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(
      context,
      () => context.actions.pay(widget.booking, _option),
      success: 'Paid ${money(_amount)}. It was added to your budget.',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final canDeposit = b.amountPaid == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.serviceTitle, style: context.text.titleMedium),
                      Text(fmtDateLong(b.eventDate), style: context.text.bodySmall),
                      const Divider(height: 24),
                      _row(context, 'Booking total', money(b.amount)),
                      _row(context, 'Already paid', money(b.amountPaid)),
                      _row(context, 'Balance', money(b.balanceDue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('What would you like to pay?', style: context.text.titleSmall),
              const SizedBox(height: 8),
              RadioGroup<PaymentOption>(
                groupValue: _option,
                onChanged: (v) => setState(() => _option = v ?? _option),
                child: Column(
                  children: [
                    if (canDeposit)
                      RadioListTile(
                        value: PaymentOption.deposit,
                        title: Text('Deposit · ${money(b.depositAmount)}'),
                        subtitle: Text('${(Booking.depositRate * 100).round()}% to confirm the booking'),
                      ),
                    RadioListTile(
                      value: PaymentOption.balance,
                      title: Text('${canDeposit ? 'Full amount' : 'Remaining balance'} · ${money(b.balanceDue)}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.colors.pillBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, size: 18, color: context.colors.roseGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Test checkout: no money is taken. Any 16-digit card number works.',
                        style: context.text.bodySmall?.copyWith(color: context.scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name on card', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the name on the card.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _card,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(labelText: 'Card number', prefixIcon: Icon(Icons.credit_card)),
                validator: (v) => (v ?? '').length == 16 ? null : 'Enter the 16-digit card number.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(labelText: 'Expiry', hintText: 'MM/YY'),
                      validator: (v) =>
                          RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch((v ?? '').trim()) ? null : 'Use MM/YY.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvc,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      decoration: const InputDecoration(labelText: 'CVC'),
                      validator: (v) => (v ?? '').length >= 3 ? null : '3 or 4 digits.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AsyncButton(label: 'Pay ${money(_amount)}', icon: Icons.lock_outline, onPressed: _pay),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: context.text.titleSmall),
      ],
    ),
  );
}
