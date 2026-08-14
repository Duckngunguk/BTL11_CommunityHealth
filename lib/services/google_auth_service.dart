import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_sync_service.dart';

class GoogleAuthService {
  GoogleAuthService._internal();

  static final GoogleAuthService instance = GoogleAuthService._internal();

  bool _nativeGoogleInitialized = false;

  Future<UserCredential> signIn() async {
    final firebaseReady = await FirebaseSyncService.instance.initialize();
    if (!firebaseReady) {
      throw GoogleAuthFailure(
        FirebaseSyncService.instance.lastError ??
            'Firebase chưa được cấu hình hoặc không thể kết nối.',
      );
    }

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters(const {'prompt': 'select_account'});
        return FirebaseAuth.instance.signInWithPopup(provider);
      }

      final supportsNativeGoogle =
          defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS;
      if (!supportsNativeGoogle) {
        throw const GoogleAuthFailure(
          'Đăng nhập Google hiện hỗ trợ Web, Android, iOS và macOS.',
        );
      }

      final googleSignIn = GoogleSignIn.instance;
      if (!_nativeGoogleInitialized) {
        await googleSignIn.initialize();
        _nativeGoogleInitialized = true;
      }
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw const GoogleAuthFailure(
          'Google không trả về mã xác thực hợp lệ.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleAuthCancelled();
      }
      throw GoogleAuthFailure(
        error.description ?? 'Không thể xác thực tài khoản Google.',
      );
    } on FirebaseAuthException catch (error) {
      throw GoogleAuthFailure(_firebaseMessage(error));
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!kIsWeb && _nativeGoogleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'operation-not-allowed' =>
        'Google chưa được bật trong Firebase Authentication.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' =>
        'Bạn đã đóng cửa sổ đăng nhập Google.',
      'popup-blocked' =>
        'Trình duyệt đã chặn cửa sổ Google. Hãy cho phép popup và thử lại.',
      'network-request-failed' =>
        'Không thể kết nối Google. Hãy kiểm tra kết nối mạng.',
      'account-exists-with-different-credential' =>
        'Email này đang sử dụng một phương thức đăng nhập khác.',
      'unauthorized-domain' =>
        'Tên miền hiện tại chưa được cho phép trong Firebase Authentication.',
      _ => error.message ?? 'Đăng nhập Google không thành công.',
    };
  }
}

class GoogleAuthFailure implements Exception {
  const GoogleAuthFailure(this.message);

  final String message;
}

class GoogleAuthCancelled implements Exception {
  const GoogleAuthCancelled();
}
