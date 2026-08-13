import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Temporary Firebase options contract.
///
/// Run `flutterfire configure` to replace this file with values generated for
/// the selected Firebase project. Until then, builds may provide the required
/// values using `--dart-define` without committing project configuration.
abstract final class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAu8tdPHrwa2zcHeHS3wBHVVAU4I7NQOEo',
    appId: '1:584439895922:web:97eafe40c1b9ed9ae02feb',
    messagingSenderId: '584439895922',
    projectId: 'community-health-demo-c007e',
    authDomain: 'community-health-demo-c007e.firebaseapp.com',
    storageBucket: 'community-health-demo-c007e.firebasestorage.app',
    measurementId: 'G-QDPTWP1QYK',
  );

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
      kIsWeb ||
      (_apiKey.isNotEmpty &&
          _appId.isNotEmpty &&
          _messagingSenderId.isNotEmpty &&
          _projectId.isNotEmpty);

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured for $defaultTargetPlatform. Run '
        '`flutterfire configure` or provide '
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
