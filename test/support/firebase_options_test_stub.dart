import 'package:firebase_core/firebase_core.dart';

// Copy to the ignored lib/firebase_options.dart only for isolated widget tests.
// No Firebase service may be initialized by these tests.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
      'Firebase is unavailable in isolated widget tests');
}
