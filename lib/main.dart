import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/demo/demo_backend.dart';
import 'data/firebase/firebase_backend.dart';
import 'data/repositories/repositories.dart';
import 'firebase_options.dart';
import 'logic/session.dart';

/// Demo mode (sample data, no Firebase) is the default. Run with
/// `--dart-define=USE_FIREBASE=true` after `flutterfire configure`.
const bool kUseFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Backend backend;
  if (kUseFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    backend = FirebaseBackend();
  } else {
    backend = DemoBackend();
  }

  final settings = AppSettings();
  await settings.load();

  runApp(DawatApp(backend: backend, settings: settings, isDemo: !kUseFirebase));
}
