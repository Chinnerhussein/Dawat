import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/service.dart';
import '../auth/validators.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Create or edit a service: title, category, pricing, capacity and
/// unavailable dates ("Manage Services, Pricing" use case).
class ServiceEditorScreen extends StatefulWidget {
  const ServiceEditorScreen({super.key, required this.provider, this.service});
  final ServiceProvider provider;
  final Service? service;

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final Service? _s = widget.service;
  late final _title = TextEditingController(text: _s?.title);
  late final _price = TextEditingController(text: _s?.price.toStringAsFixed(0));
  late final _capacity = TextEditingController(text: _s?.capacity?.toString());
  late final _description = TextEditingController(text: _s?.description);
  late ServiceCategory _category = _s?.category ?? ServiceCategory.hall;
  late PriceUnit _unit = _s?.priceUnit ?? PriceUnit.perEvent;
  late String _city = _s?.city ?? widget.provider.city;
  late bool _active = _s?.isActive ?? true;
  late List<DateTime> _blocked = [...?_s?.blockedDates]..sort();

  @override
  void dispose() {
    for (final c in [_title, _price, _capacity, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final backend = context.backend;
    final base =
        _s ??
        Service(
          id: backend.newId(),
          providerId: widget.provider.id,
          providerName: widget.provider.businessName,
          title: '',
          category: _category,
          price: 0,
          city: _city,
        );
    final updated = base.copyWith(
      title: _title.text.trim(),
      category: _category,
      price: double.parse(_price.text.replaceAll(',', '').trim()),
      priceUnit: _unit,
      city: _city,
      description: _description.text.trim(),
      capacity: int.tryParse(_capacity.text.trim()),
      blockedDates: _blocked,
      isActive: _active,
      providerName: widget.provider.businessName,
    );
    final ok = await runGuarded(
      context,
      () => backend.saveService(updated),
      success: _s == null ? 'Service published' : 'Service saved',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete this service?',
      message: 'Couples will no longer see it. Existing bookings are kept.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () => context.backend.deleteService(_s!.id), success: 'Service deleted');
    if (done && mounted) Navigator.pop(context);
  }

  Future<void> _addBlocked() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now.add(const Duration(days: 7)),
      helpText: 'Mark a date as unavailable',
      selectableDayPredicate: (d) => !_blocked.any((b) => sameDay(b, d)),
    );
    if (d != null) setState(() => _blocked = [..._blocked, d]..sort());
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _blocked.where((d) => !d.isBefore(DateTime.now().subtract(const Duration(days: 1)))).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_s == null ? 'New service' : 'Edit service'),
        actions: [
          if (_s != null)
            IconButton(tooltip: 'Delete service', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ServiceArt(category: _category, height: 110),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Service name',
                  hintText: 'e.g. Grand Ballroom, Full-Day Photo & Video',
                ),
                validator: (v) => validateRequired(v, 'a name for this service'),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price', prefixText: r'$ '),
                      validator: validateAmount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PriceUnit>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Charged'),
                      items: [for (final u in PriceUnit.values) DropdownMenuItem(value: u, child: Text(u.label))],
                      onChanged: (u) => setState(() => _unit = u ?? _unit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CityField(value: _city, cities: kCities, onChanged: (v) => setState(() => _city = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max guests', hintText: 'Optional'),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final n = int.tryParse(v!.trim());
                        return (n == null || n <= 0) ? 'Whole number' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 5,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is included, opening hours, minimum guests…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Unavailable dates', style: context.text.headlineSmall)),
                  TextButton.icon(onPressed: _addBlocked, icon: const Icon(Icons.add), label: const Text('Add date')),
                ],
              ),
              Text(
                'Couples cannot request these dates. Dates of accepted bookings are added automatically.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Text('No dates blocked. You are open every day.', style: context.text.bodyMedium)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in upcoming)
                      InputChip(
                        label: Text(fmtDate(d)),
                        onDeleted: () => setState(() => _blocked = _blocked.where((b) => !sameDay(b, d)).toList()),
                        deleteButtonTooltipMessage: 'Open this date again',
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible to couples'),
                subtitle: const Text('Turn off to pause this listing without deleting it.'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 16),
              AsyncButton(label: _s == null ? 'Publish service' : 'Save changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
