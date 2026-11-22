import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/repositories.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import 'validators.dart';

/// "Register Account" use case. Couples and service providers can sign up;
/// admin accounts are created by the Dawat team.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  UserRole _role = UserRole.couple;
  final _name = TextEditingController();
  final _partner = TextEditingController();
  final _business = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _budget = TextEditingController();
  String _city = 'erbil';
  DateTime? _weddingDate;
  bool _obscure = true;
  bool _agreed = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _partner, _business, _email, _phone, _password, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(SystemSettings settings) async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _error = 'Please agree to how Dawat uses your data.');
      return;
    }
    final backend = context.backend;
    final id = backend.newId();
    final AppUser profile = switch (_role) {
      UserRole.couple => Couple(
        id: id,
        name: _name.text.trim(),
        partnerName: _partner.text.trim(),
        email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim(),
        city: _city,
        weddingDate: _weddingDate,
        totalBudget: double.tryParse(_budget.text.replaceAll(',', '')) ?? 0,
        createdAt: DateTime.now(),
      ),
      UserRole.provider => ServiceProvider(
        id: id,
        name: _name.text.trim(),
        businessName: _business.text.trim(),
        email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim(),
        city: _city,
        approval: settings.requireProviderApproval ? ApprovalStatus.pending : ApprovalStatus.approved,
        createdAt: DateTime.now(),
      ),
      UserRole.admin => throw StateError('Admins cannot self-register'),
    };
    try {
      await backend.register(email: _email.text, password: _password.text, profile: profile);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create your account')),
    body: StreamView<SystemSettings>(
      stream: () => context.backend.watchSettings(),
      builder: (context, settings) {
        final providerAllowed = settings.allowProviderSignup;
        if (!providerAllowed && _role == UserRole.provider) _role = UserRole.couple;
        final cities = settings.enabledCities;
        if (!cities.contains(_city) && cities.isNotEmpty) _city = cities.first;
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('I am…', style: context.text.titleMedium),
                      const SizedBox(height: 10),
                      SegmentedButton<UserRole>(
                        segments: [
                          const ButtonSegment(
                            value: UserRole.couple,
                            icon: Icon(Icons.favorite_border),
                            label: Text('Bride & Groom'),
                          ),
                          ButtonSegment(
                            value: UserRole.provider,
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Provider'),
                            enabled: providerAllowed,
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) => setState(() => _role = s.first),
                      ),
                      if (_role == UserRole.provider && settings.requireProviderApproval) ...[
                        const SizedBox(height: 12),
                        _Notice(
                          'New businesses are reviewed by the Dawat team before couples can see them. '
                          'You can set up your services while you wait.',
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (_role == UserRole.provider) ...[
                        TextFormField(
                          controller: _business,
                          decoration: const InputDecoration(
                            labelText: 'Business name',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => validateRequired(v, 'your business name'),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: _role == UserRole.couple ? 'Your name' : 'Contact person',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => validateRequired(v, 'your name'),
                      ),
                      if (_role == UserRole.couple) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _partner,
                          decoration: const InputDecoration(
                            labelText: "Partner's name (optional)",
                            prefixIcon: Icon(Icons.favorite_border),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          hintText: '+964 750 000 0000',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: validatePhone,
                      ),
                      const SizedBox(height: 14),
                      CityField(value: _city, cities: cities, onChanged: (v) => setState(() => _city = v)),
                      if (_role == UserRole.couple) ...[
                        const SizedBox(height: 14),
                        DateField(
                          label: 'Wedding date (optional)',
                          value: _weddingDate,
                          firstDate: DateTime.now(),
                          onChanged: (d) => setState(() => _weddingDate = d),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _budget,
                          decoration: const InputDecoration(
                            labelText: 'Total budget in USD (optional)',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || v.trim().isEmpty) ? null : validateAmount(v, allowZero: true),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'At least 8 characters, with a number.',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'I agree that Dawat stores my details, bookings, guests and budget to run the app. '
                          'I can edit or delete them at any time.',
                          style: context.text.bodySmall?.copyWith(color: context.scheme.onSurface),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: context.scheme.error)),
                      ],
                      const SizedBox(height: 16),
                      AsyncButton(
                        label: _role == UserRole.couple ? 'Start planning' : 'Create business account',
                        onPressed: () => _submit(settings),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cities: ${cities.map(cityName).join(', ')}',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.colors.pillBg, borderRadius: BorderRadius.circular(12)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: context.colors.roseGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurface)),
        ),
      ],
    ),
  );
}
