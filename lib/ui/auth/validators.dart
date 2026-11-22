// Input validation (report §9.1). Firestore rules re-check on the server.

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Enter your email.';
  if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address.';
  return null;
}

String? validatePassword(String? v) {
  final value = v ?? '';
  if (value.length < 8) return 'Use at least 8 characters.';
  if (!value.contains(RegExp(r'[0-9]')) || !value.contains(RegExp(r'[A-Za-z]'))) {
    return 'Use letters and at least one number.';
  }
  return null;
}

String? validateRequired(String? v, String field) => (v == null || v.trim().isEmpty) ? 'Enter $field.' : null;

String? validatePhone(String? v) {
  final value = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
  if (value.isEmpty) return null; // optional
  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) return 'Enter a valid phone number.';
  return null;
}

String? validateAmount(String? v, {bool allowZero = false}) {
  final n = double.tryParse((v ?? '').replaceAll(',', '').trim());
  if (n == null) return 'Enter a number.';
  if (n < 0 || (!allowZero && n == 0)) return 'Enter an amount above zero.';
  return null;
}
