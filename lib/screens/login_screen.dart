import 'dart:async';
import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/models.dart';
import '../services/otp_service.dart';
import '../state/app_store.dart';
import '../widgets/common_widgets.dart';

enum AppMode { mobile, admin, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AppMode> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Landing Welcome Screen, 1 = Login Screen, 2 = Register Screen
  int _viewState = 0;

  // Selected role for Register/Login: 'cb' (Cán bộ Y tế) | 'ph' (Phụ huynh)
  String _selectedRole = 'cb';

  // Login Controllers
  final _usernameController = TextEditingController(text: 'ysilethu');
  final _passwordController = TextEditingController(text: '123456');
  bool _rememberMe = true;
  bool _obscureLoginPassword = true;

  // Register Controllers
  final _regFullNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  String _commune = 'Tả Phìn';

  // OTP State (viewState = 3)
  final _otpController = TextEditingController();
  String? _pendingPhone;
  String? _pendingOtpPreview;
  int _otpSecondsLeft = 120;
  Timer? _otpTimer;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _regFullNameController.dispose();
    _regPhoneController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpSecondsLeft = 120;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpSecondsLeft <= 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _otpSecondsLeft--);
      }
    });
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Tên đăng nhập hoặc Số điện thoại!'), backgroundColor: accentRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final store = AppScope.of(context);

    // Try finding exact user match in store.users
    UserModel? matchedUser;
    for (final u in store.users) {
      if (u.username == username || u.phone == username || u.email == username) {
        matchedUser = u;
        break;
      }
    }

    // Fallback search in demoUsers if not in store.users
    if (matchedUser == null) {
      for (final u in demoUsers) {
        if (u.username == username || u.phone == username) {
          matchedUser = u;
          break;
        }
      }
    }

    // Check if user is pending approval
    if (matchedUser != null && matchedUser.status == UserAccountStatus.pendingApproval) {
      setState(() => _isLoading = false);
      _showPendingApprovalDialog();
      return;
    }

    if (matchedUser != null) {
      store.currentUser = matchedUser;
      if (matchedUser.role == UserRole.parent) {
        widget.onLogin(AppMode.parent);
      } else {
        widget.onLogin(AppMode.mobile);
      }
    } else {
      // Default role based fallback if typed custom username
      if (_selectedRole == 'ph' || username.startsWith('098') || username == 'parent.demo') {
        store.currentUser = store.users.firstWhere(
          (u) => u.role == UserRole.parent,
          orElse: () => demoUsers.firstWhere((u) => u.role == UserRole.parent),
        );
        widget.onLogin(AppMode.parent);
      } else {
        store.currentUser = store.users.firstWhere(
          (u) => u.role == UserRole.healthWorker,
          orElse: () => demoUsers.firstWhere((u) => u.role == UserRole.healthWorker),
        );
        widget.onLogin(AppMode.mobile);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRegister() async {
    final name = _regFullNameController.text.trim();
    final username = _regUsernameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirm = _regConfirmPasswordController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ các thông tin bắt buộc!'), backgroundColor: accentRed),
      );
      return;
    }

    if (password != confirm && confirm.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận mật khẩu không trùng khớp!'), backgroundColor: accentRed),
      );
      return;
    }

    // For Phụ huynh: require OTP verification first
    if (_selectedRole == 'ph') {
      if (phone.isEmpty || phone.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập Số điện thoại hợp lệ để nhận mã OTP!'), backgroundColor: accentRed),
        );
        return;
      }
      setState(() => _isLoading = true);
      final result = await OtpService.instance.sendOtp(phone);
      if (mounted) setState(() => _isLoading = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: accentRed),
        );
        return;
      }
      // Go to OTP screen
      setState(() {
        _pendingPhone = phone;
        _pendingOtpPreview = result.previewOtp;
        _otpController.clear();
        _viewState = 3; // OTP verification screen
      });
      _startOtpTimer();
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final store = AppScope.of(context);
    final isHealthWorker = _selectedRole == 'cb';

    final res = await store.registerUser(
      username: username,
      fullName: name,
      email: '$username@communityhealth.local',
      phone: phone.isNotEmpty ? phone : '0987654321',
      role: isHealthWorker ? UserRole.healthWorker : UserRole.parent,
      password: password,
      assignedCommune: _commune,
    );

    // Auto fill login fields and return to Login View
    _usernameController.text = username;
    _passwordController.text = password;
    setState(() {
      _isLoading = false;
      _viewState = 1; // Return to Login Screen
    });

    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error!), backgroundColor: accentRed),
      );
      return;
    }

    if (isHealthWorker) {
      // Show Admin Approval Info Dialog for Cán bộ Y tế
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 24),
              SizedBox(width: 8),
              Text('Đăng ký thành công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Tài khoản Cán bộ Y tế của bạn đã được khởi tạo thành công!\n\n⚠️ Theo quy định, tài khoản Cán bộ Y tế cần được Quản trị viên (Admin TTYT Sa Pa) PHÊ DUYỆT trước khi có thể đăng nhập vào hệ thống.',
            style: TextStyle(fontSize: 13, height: 1.45, color: gray700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu, về Đăng nhập', style: TextStyle(fontWeight: FontWeight.w800, color: primaryDark)),
            ),
          ],
        ),
      );
    } else {
      // Toast for Parent Registration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đăng ký tài khoản Phụ huynh thành công! Vui lòng đăng nhập với tài khoản "$username".'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showPendingApprovalDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: accentRed, size: 24),
            SizedBox(width: 8),
            Text('Tài khoản chờ phê duyệt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Tài khoản Cán bộ Y tế này hiện đang CHỜ QUẢN TRỊ VIÊN PHÊ DUYỆT.\n\nVui lòng liên hệ Admin TTYT Sa Pa để được duyệt tài khoản trước khi truy cập.',
          style: TextStyle(fontSize: 13, height: 1.45, color: gray700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOtpVerify() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã OTP!'), backgroundColor: accentRed),
      );
      return;
    }
    final result = OtpService.instance.verifyOtp(_pendingPhone ?? '', enteredOtp);

    switch (result) {
      case OtpVerificationResult.success:
        _otpTimer?.cancel();
        // Now complete registration
        setState(() => _isLoading = true);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        final store = AppScope.of(context);
        final name = _regFullNameController.text.trim();
        final username = _regUsernameController.text.trim();
        final phone = _regPhoneController.text.trim();
        final password = _regPasswordController.text.trim();
        await store.registerUser(
          username: username,
          fullName: name,
          email: '$username@communityhealth.local',
          phone: phone,
          role: UserRole.parent,
          password: password,
          assignedCommune: _commune,
        );
        _usernameController.text = username;
        _passwordController.text = password;
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Xác thực thành công! Tài khoản Phụ huynh đã được tạo. Hãy đăng nhập!'),
            backgroundColor: primaryDark,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() { _viewState = 1; _pendingPhone = null; _pendingOtpPreview = null; });
        break;
      case OtpVerificationResult.expired:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏱ Mã OTP đã hết hạn! Vui lòng yêu cầu gửi lại mã.'), backgroundColor: accentRed),
        );
        break;
      case OtpVerificationResult.tooManyAttempts:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Quá nhiều lần thử! Vui lòng yêu cầu gửi OTP mới.'), backgroundColor: accentRed),
        );
        break;
      case OtpVerificationResult.invalid:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Mã OTP không chính xác! Vui lòng kiểm tra lại.'), backgroundColor: accentRed),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gray100,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_viewState) {
            0 => _buildLandingWelcomeScreen(),
            1 => _buildLoginScreen(),
            2 => _buildRegisterScreen(),
            3 => _buildOtpScreen(),
            _ => _buildLandingWelcomeScreen(),
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── VIEW 0: LANDING / WELCOME SCREEN ─────────────────────────
  // ═════════════════════════════════════════════════════════════
  Widget _buildLandingWelcomeScreen() {
    return Container(
      key: const ValueKey('landing'),
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Header Badge Logo
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Title & Tagline
                  const Text(
                    'COMMUNITY HEALTH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.04,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sổ Tay Tiêm Chủng & Giám Sát Dịch Bệnh Y Tế Cơ Sở',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: gray600,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hero Green Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047857).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'TRẠM Y TẾ XÃ TẢ PHÌN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFA7F3D0),
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Đồng hành bảo vệ sức khỏe trẻ em & Giám sát dịch tễ thực địa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Quản lý hồ sơ tiêm chủng Ngoại tuyến (Offline-First) dành cho Cán bộ y tế xã & Phụ huynh các thôn bản.',
                          style: TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 Feature Cards Overview
                  const SectionLabel('TÍNH NĂNG NỔI BẬT HỆ THỐNG'),
                  _buildFeatureCard(
                    icon: Icons.wifi_off_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                    title: 'Quản lý Hồ sơ Ngoại tuyến (Offline)',
                    subtitle: 'Ghi nhận mũi tiêm & báo dịch bình thường khi không có sóng 4G/Wifi tại các bản vùng cao.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureCard(
                    icon: Icons.qr_code_2_rounded,
                    iconColor: primaryBlue,
                    iconBg: blueLight,
                    title: 'Sổ tiêm chủng & Hộ chiếu QR',
                    subtitle: 'Theo dõi chi tiết lịch tiêm, sốt phản ứng sau tiêm & mã QR Hộ chiếu tiêm cho từng trẻ.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                    title: 'Giám sát Dịch tễ Khẩn cấp',
                    subtitle: 'Cảnh báo sớm các ca nghi mắc Sởi, Thuỷ đậu & hỗ trợ khoanh vùng dịch nhanh chóng.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Centered 'Bắt đầu ngay' Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: gray200)),
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _viewState = 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Bắt đầu ngay',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── VIEW 1: LOGIN SCREEN (Matching Attached Image 1 Exactly) ──
  // ═════════════════════════════════════════════════════════════
  Widget _buildLoginScreen() {
    return Container(
      key: const ValueKey('login_screen'),
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Centered Blue Avatar Circle Icon
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), // Solid Blue
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x292563EB),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),

              // Login Form Card Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: TÊN ĐĂNG NHẬP / SỐ ĐIỆN THOẠI
                    const Text(
                      'TÊN ĐĂNG NHẬP / SỐ ĐIỆN THOẠI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gray200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _usernameController,
                        style: const TextStyle(fontSize: 14, color: gray900, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ysilethu',
                          hintStyle: TextStyle(color: gray400),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field 2: MẬT KHẨU
                    const Text(
                      'MẬT KHẨU',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gray200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscureLoginPassword,
                        style: const TextStyle(fontSize: 14, color: gray900, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '........',
                          hintStyle: const TextStyle(color: gray400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: gray500),
                            onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Checkbox & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ghi nhớ mật khẩu',
                              style: TextStyle(fontSize: 13, color: gray700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng liên hệ Admin TTYT Sa Pa để cấp lại mật khẩu!'),
                                backgroundColor: primaryBlue,
                              ),
                            );
                          },
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row (Green Submit Button + Square Biometric Button)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669), // Emerald Green
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Đăng nhập tài khoản',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Square FaceID / Biometric Button
                  GestureDetector(
                    onTap: _handleLogin,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Footer Link: Chưa có tài khoản? Đăng ký ngay
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(fontSize: 13.5, color: gray600)),
                  GestureDetector(
                    onTap: () => setState(() => _viewState = 2), // Go to Register Screen
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF059669), fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── VIEW 2: REGISTER SCREEN (Matching Attached Image 2 Exactly) 
  // ═════════════════════════════════════════════════════════════
  Widget _buildRegisterScreen() {
    return Container(
      key: const ValueKey('register_screen'),
      color: Colors.white,
      child: Column(
        children: [
          // Header Bar (< Trở về | Đăng ký tài khoản)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _viewState = 1), // Return to login
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left_rounded, color: Color(0xFF2563EB), size: 22),
                      SizedBox(width: 2),
                      Text(
                        'Trở về',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Đăng ký tài khoản',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: gray900),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Card Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CHỌN VAI TRỜ TÀI KHOẢN ĐĂNG KÝ
                        const Text(
                          'CHỌN VAI TRỜ TÀI KHOẢN ĐĂNG KÝ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 8),

                        // Radio Pill Row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = 'cb'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedRole == 'cb' ? const Color(0xFF059669) : gray200,
                                      width: _selectedRole == 'cb' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF059669), width: 2),
                                          color: _selectedRole == 'cb' ? const Color(0xFF059669) : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cán bộ Y tế',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedRole == 'cb' ? gray900 : gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = 'ph'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedRole == 'ph' ? const Color(0xFF059669) : gray200,
                                      width: _selectedRole == 'ph' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _selectedRole == 'ph' ? const Color(0xFF059669) : gray400, width: 2),
                                          color: _selectedRole == 'ph' ? const Color(0xFF059669) : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Phụ huynh',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedRole == 'ph' ? gray900 : gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Field 1: HỌ VÀ TÊN NGƯỜI SỬ DỤNG
                        const Text(
                          'HỌ VÀ TÊN NGƯỜI SỬ DỤNG',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(_regFullNameController, 'Ví dụ: Nguyễn Mạnh Đức'),
                        const SizedBox(height: 14),

                        // Field 2: SỐ ĐIỆN THOẠI LIÊN HỆ
                        const Text(
                          'SỐ ĐIỆN THOẠI LIÊN HỆ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(_regPhoneController, 'Ví dụ: 0987654321', keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),

                        // Field 3: TÊN ĐĂNG NHẬP
                        const Text(
                          'TÊN ĐĂNG NHẬP',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(_regUsernameController, 'Nhập tài khoản mong muốn'),
                        const SizedBox(height: 14),

                        // Field 4: MẬT KHẨU BẢO MẬT
                        const Text(
                          'MẬT KHẨU BẢO MẬT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(_regPasswordController, 'Nhập mật khẩu dài từ 6 ký tự', obscureText: _obscureRegPassword),
                        const SizedBox(height: 14),

                        // Field 5: XÁC NHẬN MẬT KHẨU
                        const Text(
                          'XÁC NHẬN MẬT KHẨU',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gray700, letterSpacing: 0.02),
                        ),
                        const SizedBox(height: 6),
                        _buildInputField(_regConfirmPasswordController, 'Nhập lại mật khẩu để xác thực', obscureText: _obscureRegPassword),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Green Submit Button: Đăng ký tài khoản
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // Emerald Green
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Đăng ký tài khoản',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer Link: Đã có tài khoản? Đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản? ', style: TextStyle(fontSize: 13.5, color: gray600)),
                      GestureDetector(
                        onTap: () => setState(() => _viewState = 1), // Switch back to login screen
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF059669), fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13.5, color: gray900, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: gray400, fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: gray900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: gray600, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── VIEW 3: OTP VERIFICATION SCREEN ──────────────────────────
  // ═════════════════════════════════════════════════════════════
  Widget _buildOtpScreen() {
    final minutes = _otpSecondsLeft ~/ 60;
    final secs = _otpSecondsLeft % 60;
    final timeStr = '$minutes:${secs.toString().padLeft(2, '0')}';
    final expired = _otpSecondsLeft <= 0;

    return Container(
      key: const ValueKey('otp'),
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _viewState = 2),
                  child: const Icon(Icons.arrow_back_rounded, color: gray700),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Xác thực OTP',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: gray900),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // OTP Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.sms_rounded, color: Color(0xFF2563EB), size: 38),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nhập mã xác thực',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gray900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã OTP 6 chữ số đã được gửi đến\n${_pendingPhone ?? ""}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: gray600, height: 1.5),
                  ),

                  // Demo hint – only shown in debug
                  if (_pendingOtpPreview != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Text(
                            'Demo – Mã OTP: $_pendingOtpPreview',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // OTP Input (6 digits as single field)
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    enabled: !expired,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: gray900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '——————',
                      hintStyle: const TextStyle(letterSpacing: 8, color: Color(0xFFCBD5E1), fontSize: 24),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Countdown timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        expired ? Icons.timer_off_rounded : Icons.timer_outlined,
                        size: 16,
                        color: expired ? accentRed : gray600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        expired ? 'Mã OTP đã hết hạn' : 'Mã hết hạn sau $timeStr',
                        style: TextStyle(
                          fontSize: 13,
                          color: expired ? accentRed : gray600,
                          fontWeight: expired ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!expired && !_isLoading) ? _handleOtpVerify : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: gray200,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Xác nhận OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend button
                  TextButton.icon(
                    onPressed: _otpSecondsLeft <= 0
                        ? () async {
                            final phone = _pendingPhone ?? '';
                            setState(() => _isLoading = true);
                            final result = await OtpService.instance.sendOtp(phone);
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _pendingOtpPreview = result.previewOtp;
                              });
                              _startOtpTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: primaryDark,
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Gửi lại mã OTP', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

