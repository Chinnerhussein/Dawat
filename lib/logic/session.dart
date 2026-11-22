import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/app_user.dart';
import '../data/repositories/repositories.dart';
import 'booking_actions.dart';

/// Holds the signed-in user and rebuilds the app when it changes.
class Session extends ChangeNotifier {
  Session(this.backend) {
    _sub = backend.userChanges().listen((user) {
      final wasSignedOut = _user == null;
      _user = user;
      _ready = true;
      notifyListeners();
      if (wasSignedOut && user is Couple) {
        unawaited(createDueReminders(backend, user));
      }
    });
  }

  final Backend backend;
  late final StreamSubscription<AppUser?> _sub;
  AppUser? _user;
  bool _ready = false;

  AppUser? get user => _user;

  /// False until the backend has reported the first auth state.
  bool get ready => _ready;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Theme preference (Henna Night is dark-first), saved on the device.
class AppSettings extends ChangeNotifier {
  static const _key = 'themeMode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        _mode = ThemeMode.values.byName(saved);
        notifyListeners();
      }
    } catch (_) {
      // Preferences are a convenience; fall back to the default.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}
