import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/planner.dart';
import '../auth/validators.dart';
import '../widgets/common.dart';

/// "Manage Guest List & RSVPs" use case.
class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key, required this.couple});
  final Couple couple;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  RsvpStatus? _filter;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guest list')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editGuest(context, widget.couple),
      icon: const Icon(Icons.person_add_alt),
      label: const Text('Add guest'),
    ),
    body: StreamView<List<Guest>>(
      stream: () => context.backend.watchGuests(widget.couple.id),
      builder: (context, guests) {
        int people(RsvpStatus? s) =>
            guests.where((g) => s == null || g.rsvpStatus == s).fold(0, (a, g) => a + g.partySize);
        final q = _search.text.trim().toLowerCase();
        final shown = guests
            .where(
              (g) =>
                  (_filter == null || g.rsvpStatus == _filter) && (q.isEmpty || g.fullName.toLowerCase().contains(q)),
            )
            .toList();
        final c = context.colors;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatTile(label: 'Invited people', value: '${people(null)}', icon: Icons.mail_outline),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      label: 'Attending',
                      value: '${people(RsvpStatus.attending)}',
                      icon: Icons.check_circle_outline,
                      color: c.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      label: 'Awaiting',
                      value: '${people(RsvpStatus.pending)}',
                      icon: Icons.hourglass_empty,
                      color: c.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Search guests', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('All (${guests.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final s in RsvpStatus.values)
                  ChoiceChip(
                    label: Text('${s.label} (${guests.where((g) => g.rsvpStatus == s).length})'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (shown.isEmpty)
              EmptyState(
                icon: Icons.people_outline,
                title: guests.isEmpty ? 'No guests yet' : 'No guests match',
                message: guests.isEmpty
                    ? 'Add families and friends, then track who is coming.'
                    : 'Try another filter or search.',
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final g in shown) ...[
                      _GuestTile(guest: g, couple: widget.couple),
                      if (g != shown.last) const Divider(indent: 72),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({required this.guest, required this.couple});
  final Guest guest;
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final g = guest;
    return ListTile(
      onTap: () => _editGuest(context, couple, guest: g),
      leading: CircleAvatar(
        backgroundColor: rsvpColor(context, g.rsvpStatus).withValues(alpha: 0.16),
        child: Text(
          g.fullName.isEmpty ? '?' : g.fullName[0],
          style: TextStyle(color: rsvpColor(context, g.rsvpStatus), fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(g.fullName, style: context.text.titleSmall),
      subtitle: Text(
        [
          g.partySize == 1 ? '1 person' : '${g.partySize} people',
          g.side.label,
          if (g.tableNo != null) 'Table ${g.tableNo}',
        ].join(' · '),
      ),
      trailing: PopupMenuButton<RsvpStatus>(
        tooltip: 'Change RSVP',
        onSelected: (s) => context.backend.saveGuest(g.updateRsvp(s)),
        itemBuilder: (_) => [for (final s in RsvpStatus.values) PopupMenuItem(value: s, child: Text(s.label))],
        child: StatusPill(g.rsvpStatus.label, color: rsvpColor(context, g.rsvpStatus)),
      ),
    );
  }
}

Future<void> _editGuest(BuildContext context, Couple couple, {Guest? guest}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _GuestSheet(couple: couple, guest: guest),
);

class _GuestSheet extends StatefulWidget {
  const _GuestSheet({required this.couple, this.guest});
  final Couple couple;
  final Guest? guest;

  @override
  State<_GuestSheet> createState() => _GuestSheetState();
}

class _GuestSheetState extends State<_GuestSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.guest?.fullName);
  late final _phone = TextEditingController(text: widget.guest?.phone);
  late final _table = TextEditingController(text: widget.guest?.tableNo?.toString());
  late int _party = widget.guest?.partySize ?? 1;
  late GuestSide _side = widget.guest?.side ?? GuestSide.both;
  late RsvpStatus _rsvp = widget.guest?.rsvpStatus ?? RsvpStatus.pending;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _table.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final backend = context.backend;
    final table = int.tryParse(_table.text.trim());
    final guest = Guest(
      id: widget.guest?.id ?? backend.newId(),
      userId: widget.couple.id,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      side: _side,
      partySize: _party,
      rsvpStatus: _rsvp,
      tableNo: table,
    );
    final ok = await runGuarded(
      context,
      () => backend.saveGuest(guest),
      success: widget.guest == null ? 'Guest added' : 'Guest updated',
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
              Text(widget.guest == null ? 'New guest' : 'Edit guest', style: context.text.headlineMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name or family name'),
                validator: (v) => validateRequired(v, 'a name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                validator: validatePhone,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text('People in this invitation', style: context.text.titleSmall)),
                  IconButton.outlined(
                    tooltip: 'Fewer',
                    onPressed: _party > 1 ? () => setState(() => _party--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('$_party', textAlign: TextAlign.center, style: context.text.titleMedium),
                  ),
                  IconButton.outlined(
                    tooltip: 'More',
                    onPressed: _party < 30 ? () => setState(() => _party++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<GuestSide>(
                segments: [for (final s in GuestSide.values) ButtonSegment(value: s, label: Text(s.label))],
                selected: {_side},
                onSelectionChanged: (s) => setState(() => _side = s.first),
              ),
              const SizedBox(height: 14),
              Text('RSVP', style: context.text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<RsvpStatus>(
                segments: [for (final s in RsvpStatus.values) ButtonSegment(value: s, label: Text(s.label))],
                selected: {_rsvp},
                onSelectionChanged: (s) => setState(() => _rsvp = s.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _table,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Table number (optional)'),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  final n = int.tryParse(v!.trim());
                  return (n == null || n <= 0) ? 'Enter a table number.' : null;
                },
              ),
              const SizedBox(height: 18),
              AsyncButton(label: 'Save guest', onPressed: _save),
              if (widget.guest != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: context.colors.danger),
                  onPressed: () async {
                    final ok = await runGuarded(
                      context,
                      () => context.backend.deleteGuest(widget.guest!.id),
                      success: 'Guest removed',
                    );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove guest'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
