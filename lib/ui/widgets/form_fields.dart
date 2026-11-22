import 'package:material_ui/material_ui.dart';

import '../../core/utils/format.dart';

class CityField extends StatelessWidget {
  const CityField({super.key, required this.value, required this.cities, required this.onChanged, this.label = 'City'});
  final String value;
  final List<String> cities;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final options = cities.contains(value) ? cities : [value, ...cities];
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.place_outlined)),
      items: [for (final c in options) DropdownMenuItem(value: c, child: Text(cityName(c)))],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

/// Read-only field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectable,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool Function(DateTime)? selectable;
  final String? Function(DateTime?)? validator;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 1);
    var initial = value ?? now.add(const Duration(days: 30));
    if (initial.isBefore(first)) initial = first;
    // The picker requires the initial date itself to be selectable.
    if (selectable != null) {
      var probe = initial;
      for (var i = 0; i < 730 && !selectable!(probe); i++) {
        probe = probe.add(const Duration(days: 1));
      }
      initial = probe;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: lastDate ?? DateTime(now.year + 3),
      selectableDayPredicate: selectable,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    initialValue: value,
    validator: validator == null ? null : (_) => validator!(value),
    builder: (state) => InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: const Icon(Icons.expand_more),
          errorText: state.errorText,
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : fmtDateLong(value!)),
      ),
    ),
  );
}
