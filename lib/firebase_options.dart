import 'package:firebase_core/firebase_core.dart';

/// Temporary Firebase options contract.
///
/// Run `flutterfire configure` to replace this file with values generated for
/// the selected Firebase project. Until then, builds may provide the required
/// values using `--dart-define` without committing project configuration.
abstract final class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured. Run `flutterfire configure` or provide '
        'FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID and '
        'FIREBASE_PROJECT_ID using --dart-define.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
