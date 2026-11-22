import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../logic/session.dart';
import '../auth/validators.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// "Edit a profile" (§6.4) for all three actors.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final AppUser _user = context.read<Session>().user!;
  late final _name = TextEditingController(text: _user.name);
  late final _phone = TextEditingController(text: _user.phone);
  late String _city = _user.city;
  late final _partner = TextEditingController(text: _user is Couple ? (_user).partnerName : '');
  late DateTime? _wedding = _user is Couple ? (_user).weddingDate : null;
  late final _budget = TextEditingController(
    text: _user is Couple && (_user).totalBudget > 0 ? (_user).totalBudget.toStringAsFixed(0) : '',
  );
  late final _business = TextEditingController(text: _user is ServiceProvider ? (_user).businessName : '');
  late final _bio = TextEditingController(text: _user is ServiceProvider ? (_user).bio : '');

  @override
  void dispose() {
    for (final c in [_name, _phone, _partner, _budget, _business, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final current = context.read<Session>().user ?? _user;
    final AppUser updated = switch (current) {
      Couple c => c.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _city,
        partnerName: _partner.text.trim(),
        weddingDate: _wedding,
        totalBudget: double.tryParse(_budget.text.replaceAll(',', '')) ?? c.totalBudget,
      ),
      ServiceProvider p => p.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _city,
        businessName: _business.text.trim(),
        bio: _bio.text.trim(),
      ),
      Admin a => a.copyWith(name: _name.text.trim(), phone: _phone.text.trim(), city: _city),
    };
    final ok = await runGuarded(context, () => context.backend.updateProfile(updated), success: 'Profile saved');
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('${roleName(u.role)} account · ${u.email}', style: context.text.bodySmall),
              const SizedBox(height: 16),
              if (u is ServiceProvider) ...[
                TextFormField(
                  controller: _business,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (v) => validateRequired(v, 'your business name'),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: u is ServiceProvider ? 'Contact person' : 'Your name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => validateRequired(v, 'your name'),
              ),
              if (u is Couple) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _partner,
                  decoration: const InputDecoration(
                    labelText: "Partner's name",
                    prefixIcon: Icon(Icons.favorite_border),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                validator: validatePhone,
              ),
              const SizedBox(height: 14),
              CityField(value: _city, cities: kCities, onChanged: (v) => setState(() => _city = v)),
              if (u is Couple) ...[
                const SizedBox(height: 14),
                DateField(
                  label: 'Wedding date',
                  value: _wedding,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  onChanged: (d) => setState(() => _wedding = d),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _budget,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total budget (USD)',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? null : validateAmount(v, allowZero: true),
                ),
              ],
              if (u is ServiceProvider) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 400,
                  decoration: const InputDecoration(labelText: 'About your business', alignLabelWithHint: true),
                ),
              ],
              const SizedBox(height: 20),
              AsyncButton(label: 'Save changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
