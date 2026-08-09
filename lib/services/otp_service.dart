import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Kết quả xác thực OTP
enum OtpVerificationResult { success, invalid, expired, tooManyAttempts }

/// Dịch vụ OTP – Mô phỏng (demo) & sẵn sàng tích hợp Twilio / VNAS SMS
class OtpService {
  OtpService._internal();
  static final OtpService instance = OtpService._internal();

  String? _currentOtp;
  String? _currentPhone;
  DateTime? _otpSentAt;
  int _attemptCount = 0;

  static const int _otpExpirySeconds = 120; // 2 phút
  static const int _maxAttempts = 5;

  /// Gửi OTP 6 chữ số đến số điện thoại
  /// Trong production: tích hợp Twilio API / VNAS SMS / Zalo ZNS tại đây
  Future<({bool success, String message, String? previewOtp})> sendOtp(
      String phoneNumber) async {
    // Mô phỏng độ trễ mạng
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Sinh mã OTP 6 số ngẫu nhiên
    final otp = _generateOtp();
    _currentOtp = otp;
    _currentPhone = phoneNumber;
    _otpSentAt = DateTime.now();
    _attemptCount = 0;

    // [PRODUCTION] Gọi API SMS thực tại đây:
    // await _sendViaTwilio(phoneNumber, otp);
    // await _sendViaVNAS(phoneNumber, otp);
    // await _sendViaZaloZNS(phoneNumber, otp);

    debugPrint('📱 [OTP Service - Demo Mode] OTP: $otp → Phone: $phoneNumber');

    // Trong chế độ demo, trả về OTP để hiển thị cho người dùng test
    return (
      success: true,
      message: 'Mã OTP đã được gửi đến $phoneNumber',
      previewOtp: kDebugMode ? otp : null,
    );
  }

  /// Xác minh mã OTP người dùng nhập
  OtpVerificationResult verifyOtp(String phoneNumber, String enteredOtp) {
    if (_attemptCount >= _maxAttempts) {
      return OtpVerificationResult.tooManyAttempts;
    }

    if (_currentPhone != phoneNumber || _currentOtp == null || _otpSentAt == null) {
      return OtpVerificationResult.invalid;
    }

    final elapsed = DateTime.now().difference(_otpSentAt!).inSeconds;
    if (elapsed > _otpExpirySeconds) {
      _clearOtp();
      return OtpVerificationResult.expired;
    }

    _attemptCount++;

    if (enteredOtp.trim() == _currentOtp) {
      _clearOtp();
      debugPrint('✅ [OTP Service] OTP xác thực thành công cho: $phoneNumber');
      return OtpVerificationResult.success;
    }

    return OtpVerificationResult.invalid;
  }

  /// Kiểm tra thời gian còn lại của OTP
  int get remainingSeconds {
    if (_otpSentAt == null) return 0;
    final elapsed = DateTime.now().difference(_otpSentAt!).inSeconds;
    return (_otpExpirySeconds - elapsed).clamp(0, _otpExpirySeconds);
  }

  bool get hasActiveOtp => _currentOtp != null && remainingSeconds > 0;

  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  void _clearOtp() {
    _currentOtp = null;
    _currentPhone = null;
    _otpSentAt = null;
    _attemptCount = 0;
  }
}
