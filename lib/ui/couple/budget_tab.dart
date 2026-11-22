import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/planner.dart';
import '../../data/models/service.dart';
import '../auth/validators.dart';
import '../widgets/common.dart';

/// "Manage Budget & Expenses" use case (concept screen B3).
class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editExpense(context, couple),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: StreamView<List<BudgetExpense>>(
          stream: () => backend.watchExpenses(couple.id),
          builder: (context, expenses) => StreamView<List<Booking>>(
            stream: () => backend.watchCoupleBookings(couple.id),
            builder: (context, bookings) {
              final spent = expenses.fold<double>(0, (a, e) => a + e.amount);
              // Money promised to confirmed vendors but not paid yet.
              final committed = bookings
                  .where((b) => b.status == BookingStatus.accepted)
                  .fold<double>(0, (a, b) => a + b.balanceDue);
              final total = couple.totalBudget;
              final remaining = total - spent - committed;
              final byCategory = <ServiceCategory, double>{};
              for (final e in expenses) {
                byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
              }
              final cats = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Text('Budget', style: context.text.displaySmall),
                  const SizedBox(height: 16),
                  HennaHero(
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Total budget', style: context.text.bodyMedium?.copyWith(color: heroMuted)),
                            const Spacer(),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: context.colors.glow,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _editTotal(context, couple),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        Text(
                          total > 0 ? money(total) : 'Not set',
                          style: context.text.displaySmall?.copyWith(color: heroInk, fontStyle: FontStyle.normal),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeroFigure('Spent', money(spent)),
                            _HeroFigure('Committed', money(committed)),
                            _HeroFigure('Left', money(remaining), warn: total > 0 && remaining < 0),
                          ],
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (value, color) in [
                                    (spent, context.colors.glow),
                                    (committed, context.colors.glow.withValues(alpha: 0.45)),
                                    (remaining, Colors.white.withValues(alpha: 0.12)),
                                  ])
                                    if ((value / total * 1000).round() > 0)
                                      Expanded(
                                        flex: (value / total * 1000).clamp(1, 1000).round(),
                                        child: ColoredBox(color: color),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remaining < 0
                                ? 'You are ${money(-remaining)} over budget once confirmed bookings are paid.'
                                : '${((spent + committed) / total * 100).round()}% of your budget is spent or committed.',
                            style: context.text.bodySmall?.copyWith(
                              color: remaining < 0 ? context.colors.roseGold : heroMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (cats.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Spending by category', style: context.text.headlineSmall),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final e in cats) ...[
                              Row(
                                children: [
                                  Icon(e.key.icon, size: 20, color: context.scheme.primary),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(e.key.label, style: context.text.titleSmall)),
                                  Text(money(e.value), style: context.text.titleSmall),
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      '${(e.value / spent * 100).round()}%',
                                      textAlign: TextAlign.end,
                                      style: context.text.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LabeledBar(value: e.value / spent),
                              if (e != cats.last) const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Expenses', style: context.text.headlineSmall),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses yet',
                      message: 'Add what you spend. Payments for bookings are added automatically.',
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final e in expenses) ...[
                            ListTile(
                              onTap: () => _editExpense(context, couple, expense: e),
                              leading: CircleAvatar(
                                backgroundColor: context.scheme.primary.withValues(alpha: 0.14),
                                child: Icon(e.category.icon, size: 20, color: context.scheme.primary),
                              ),
                              title: Text(e.title, style: context.text.titleSmall),
                              subtitle: Text(
                                [
                                  e.category.label,
                                  if (e.createdAt != null) fmtDate(e.createdAt!),
                                  if (e.bookingId != null) 'From booking',
                                ].join(' · '),
                              ),
                              trailing: Text(money(e.amount), style: context.text.titleSmall),
                            ),
                            if (e != expenses.last) const Divider(indent: 72),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure(this.label, this.value, {this.warn = false});
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.bodySmall?.copyWith(color: heroMuted)),
        const SizedBox(height: 2),
        Text(value, style: context.text.titleMedium?.copyWith(color: warn ? context.colors.roseGold : heroInk)),
      ],
    ),
  );
}

Future<void> _editTotal(BuildContext context, Couple couple) async {
  final controller = TextEditingController(text: couple.totalBudget > 0 ? couple.totalBudget.toStringAsFixed(0) : '');
  final formKey = GlobalKey<FormState>();
  final value = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Total budget', style: ctx.text.headlineSmall),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: r'$ ', labelText: 'Amount in USD'),
          validator: (v) => validateAmount(v, allowZero: true),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, double.parse(controller.text.replaceAll(',', '').trim()));
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (value != null && context.mounted) {
    await runGuarded(
      context,
      () => context.backend.updateProfile(couple.copyWith(totalBudget: value)),
      success: 'Budget updated',
    );
  }
}

Future<void> _editExpense(BuildContext context, Couple couple, {BudgetExpense? expense}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ExpenseSheet(couple: couple, expense: expense),
);

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.couple, this.expense});
  final Couple couple;
  final BudgetExpense? expense;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _amount = TextEditingController(text: widget.expense?.amount.toStringAsFixed(0));
  late ServiceCategory _category = widget.expense?.category ?? ServiceCategory.other;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final backend = context.backend;
    final e = widget.expense;
    final expense = BudgetExpense(
      id: e?.id ?? backend.newId(),
      userId: widget.couple.id,
      title: _title.text.trim(),
      amount: double.parse(_amount.text.replaceAll(',', '').trim()),
      category: _category,
      bookingId: e?.bookingId,
      createdAt: e?.createdAt ?? DateTime.now(),
    );
    final ok = await runGuarded(
      context,
      () => backend.saveExpense(expense),
      success: e == null ? 'Expense added' : 'Expense updated',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
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
              Text(widget.expense == null ? 'New expense' : 'Edit expense', style: context.text.headlineMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What was it for?'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a description.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', prefixText: r'$ '),
                validator: validateAmount,
              ),
              const SizedBox(height: 14),
              Text('Category', style: context.text.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ServiceCategory.values)
                    ChoiceChip(
                      avatar: Icon(
                        c.icon,
                        size: 16,
                        color: _category == c ? context.scheme.onPrimary : context.colors.muted,
                      ),
                      showCheckmark: false,
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AsyncButton(label: 'Save expense', onPressed: _save),
              if (widget.expense != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: context.colors.danger),
                  onPressed: () async {
                    final ok = await runGuarded(
                      context,
                      () => context.backend.deleteExpense(widget.expense!.id),
                      success: 'Expense deleted',
                    );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete expense'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
