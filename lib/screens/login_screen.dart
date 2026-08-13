import 'dart:async';
import 'package:flutter/material.dart';

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
  // 1 = Login Screen, 2 = Register Screen, 3 = OTP verification.
  // Ứng dụng nội bộ luôn mở thẳng màn đăng nhập; không public dữ liệu vận hành.
  int _viewState = 1;

  // Selected role for Register/Login: 'cb' (Cán bộ Y tế) | 'ph' (Phụ huynh)
  String _selectedRole = 'cb';

  // Login Controllers
  final _usernameController = TextEditingController(text: 'healthworker.demo');
  final _passwordController = TextEditingController(text: '123456');
  bool _rememberMe = true;
  bool _obscureLoginPassword = true;

  // Register Controllers
  final _regFullNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final bool _obscureRegPassword = true;
  final String _commune = 'Tả Phìn';

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
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ tài khoản và mật khẩu!'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final store = AppScope.of(context);
    final response = await store.authenticate(
      username: username,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!response.success || response.data == null) {
      if (response.statusCode == 403) {
        _showPendingApprovalDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Không thể đăng nhập.'),
            backgroundColor: accentRed,
          ),
        );
      }
      return;
    }

    switch (response.data!.role) {
      case UserRole.admin:
        widget.onLogin(AppMode.admin);
      case UserRole.parent:
        widget.onLogin(AppMode.parent);
      case UserRole.healthWorker:
        widget.onLogin(AppMode.mobile);
    }
  }

  Future<void> _handleRegister() async {
    final name = _regFullNameController.text.trim();
    final username = _regUsernameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirm = _regConfirmPasswordController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập đầy đủ các thông tin bắt buộc!'),
            backgroundColor: accentRed),
      );
      return;
    }

    if (password != confirm && confirm.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Xác nhận mật khẩu không trùng khớp!'),
            backgroundColor: accentRed),
      );
      return;
    }

    // For Phụ huynh: require OTP verification first
    if (_selectedRole == 'ph') {
      if (phone.isEmpty || phone.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Vui lòng nhập Số điện thoại hợp lệ để nhận mã OTP!'),
              backgroundColor: accentRed),
        );
        return;
      }
      setState(() => _isLoading = true);
      final result = await OtpService.instance.sendOtp(phone);
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    if (!mounted) return;
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
    if (!mounted) return;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: Color(0xFFD97706), size: 24),
              SizedBox(width: 8),
              Text('Đăng ký thành công',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Tài khoản Cán bộ Y tế của bạn đã được khởi tạo thành công!\n\n⚠️ Theo quy định, tài khoản Cán bộ Y tế cần được Quản trị viên (Admin TTYT Sa Pa) PHÊ DUYỆT trước khi có thể đăng nhập vào hệ thống.',
            style: TextStyle(fontSize: 13, height: 1.45, color: gray700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu, về Đăng nhập',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: primaryDark)),
            ),
          ],
        ),
      );
    } else {
      // Toast for Parent Registration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Đăng ký tài khoản Phụ huynh thành công! Vui lòng đăng nhập với tài khoản "$username".'),
          backgroundColor: primaryDark,
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
            Text('Tài khoản chờ phê duyệt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Tài khoản Cán bộ Y tế này hiện đang CHỜ QUẢN TRỊ VIÊN PHÊ DUYỆT.\n\nVui lòng liên hệ Admin TTYT Sa Pa để được duyệt tài khoản trước khi truy cập.',
          style: TextStyle(fontSize: 13, height: 1.45, color: gray700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOtpVerify() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập đủ 6 chữ số mã OTP!'),
            backgroundColor: accentRed),
      );
      return;
    }
    final result =
        OtpService.instance.verifyOtp(_pendingPhone ?? '', enteredOtp);

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
            content: Text(
                '✅ Xác thực thành công! Tài khoản Phụ huynh đã được tạo. Hãy đăng nhập!'),
            backgroundColor: primaryDark,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _viewState = 1;
          _pendingPhone = null;
          _pendingOtpPreview = null;
        });
        break;
      case OtpVerificationResult.expired:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('⏱ Mã OTP đã hết hạn! Vui lòng yêu cầu gửi lại mã.'),
              backgroundColor: accentRed),
        );
        break;
      case OtpVerificationResult.tooManyAttempts:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('⚠️ Quá nhiều lần thử! Vui lòng yêu cầu gửi OTP mới.'),
              backgroundColor: accentRed),
        );
        break;
      case OtpVerificationResult.invalid:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Mã OTP không chính xác! Vui lòng kiểm tra lại.'),
              backgroundColor: accentRed),
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
            _ => _buildLoginScreen(),
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
      color: pageBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final horizontal = isWide ? 40.0 : 20.0;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1180,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AppLogo(compact: !isWide),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _viewState = 1),
                            child: const Text('Đăng nhập'),
                          ),
                        ],
                      ),
                      SizedBox(height: isWide ? 88 : 52),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildLandingCopy(true)),
                            const SizedBox(width: 72),
                            Expanded(child: _buildLandingPreview()),
                          ],
                        )
                      else ...[
                        _buildLandingCopy(false),
                        const SizedBox(height: 36),
                        _buildLandingPreview(),
                      ],
                      SizedBox(height: isWide ? 72 : 40),
                      const Text(
                        'Dữ liệu sức khỏe được quản lý an toàn • Hỗ trợ vận hành ngoại tuyến',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: gray500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandingCopy(bool isWide) {
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'NỀN TẢNG Y TẾ CỘNG ĐỒNG',
            style: TextStyle(
              color: primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Chăm sóc chủ động.\nDữ liệu liền mạch.',
          textAlign: isWide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: gray900,
            fontSize: isWide ? 46 : 34,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Text(
            'Một không gian làm việc thống nhất cho cán bộ y tế, phụ huynh và quản trị viên—từ hồ sơ tiêm chủng đến giám sát dịch tễ.',
            style: TextStyle(color: gray600, fontSize: 16, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => setState(() => _viewState = 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              label: const Text('Bắt đầu ngay'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _viewState = 2),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandingPreview() {
    return AppSurface(
      shadow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppLogo(size: 36, compact: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạm Y tế xã Tả Phìn',
                      style: TextStyle(
                        color: gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tổng quan hoạt động hôm nay',
                      style: TextStyle(color: gray500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: gray400),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _landingMetric(
                  'Hồ sơ theo dõi',
                  '128',
                  Icons.folder_shared_outlined,
                  blueLight,
                  primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _landingMetric(
                  'Đúng lịch',
                  '94%',
                  Icons.verified_outlined,
                  primaryLight,
                  primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Tiến độ tiêm chủng',
            style: TextStyle(color: gray900, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: .82,
              minHeight: 9,
              backgroundColor: gray100,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('Đã hoàn thành 82%', style: TextStyle(color: gray600)),
              Text('Mục tiêu 95%', style: TextStyle(color: gray500)),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: yellowLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule_rounded, color: accentYellow, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '4 trẻ cần được liên hệ trước phiên tiêm tiếp theo.',
                    style: TextStyle(
                      color: gray800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _landingMetric(
    String label,
    String value,
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: gray600, fontSize: 12)),
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
      color: pageBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: gray200),
                    boxShadow: const [appSurfaceShadow],
                  ),
                  child: isDesktop
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 9, child: _buildAuthBrandPanel()),
                              Expanded(flex: 10, child: _buildLoginForm(true)),
                            ],
                          ),
                        )
                      : _buildLoginForm(false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthBrandPanel() {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(42),
      color: const Color(0xFF123C3A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const Spacer(),
          const Text(
            'Chăm sóc cộng đồng\nbắt đầu từ dữ liệu tốt.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Theo dõi tiêm chủng, phối hợp gia đình và phản ứng sớm với nguy cơ dịch tễ trên một nền tảng duy nhất.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          const _LoginTrustItem(
            icon: Icons.cloud_done_outlined,
            text: 'Sẵn sàng làm việc trực tuyến và ngoại tuyến',
          ),
          const SizedBox(height: 14),
          const _LoginTrustItem(
            icon: Icons.lock_outline_rounded,
            text: 'Phân quyền truy cập theo từng vai trò',
          ),
          const Spacer(),
          Text(
            'CommunityHealth • Tả Phìn, Sa Pa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .52),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 48 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AppLogo(size: 40),
          ),
          SizedBox(height: isDesktop ? 36 : 32),
          const Text(
            'Chào mừng trở lại',
            style: TextStyle(
              color: gray900,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để tiếp tục vào không gian làm việc của bạn.',
            style: TextStyle(color: gray600, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 30),
          const Text(
            'Tài khoản hoặc số điện thoại',
            style: TextStyle(
              color: gray800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              hintText: 'Nhập tài khoản của bạn',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mật khẩu',
            style: TextStyle(
              color: gray800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscureLoginPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!_isLoading) _handleLogin();
            },
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip:
                    _obscureLoginPassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () => setState(
                  () => _obscureLoginPassword = !_obscureLoginPassword,
                ),
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Flexible(
                      child: Text(
                        'Duy trì đăng nhập',
                        style: TextStyle(color: gray600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng liên hệ quản trị viên để được cấp lại mật khẩu.',
                      ),
                    ),
                  );
                },
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Đăng nhập'),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản?',
                style: TextStyle(color: gray600, fontSize: 13),
              ),
              TextButton(
                onPressed: () => setState(() => _viewState = 2),
                child: const Text('Đăng ký'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: gray400),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Phiên đăng nhập được bảo vệ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gray500, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
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
                  onTap: () =>
                      setState(() => _viewState = 1), // Return to login
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left_rounded,
                          color: primaryDark, size: 22),
                      SizedBox(width: 2),
                      Text(
                        'Trở về',
                        style: TextStyle(
                            color: primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Đăng ký tài khoản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: gray900),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 8),

                            // Radio Pill Row
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedRole = 'cb'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedRole == 'cb'
                                              ? primaryDark
                                              : gray200,
                                          width:
                                              _selectedRole == 'cb' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: primaryDark, width: 2),
                                              color: _selectedRole == 'cb'
                                                  ? primaryDark
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cán bộ Y tế',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: _selectedRole == 'cb'
                                                  ? gray900
                                                  : gray600,
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
                                    onTap: () =>
                                        setState(() => _selectedRole = 'ph'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedRole == 'ph'
                                              ? primaryDark
                                              : gray200,
                                          width:
                                              _selectedRole == 'ph' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _selectedRole == 'ph'
                                                      ? primaryDark
                                                      : gray400,
                                                  width: 2),
                                              color: _selectedRole == 'ph'
                                                  ? primaryDark
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Phụ huynh',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: _selectedRole == 'ph'
                                                  ? gray900
                                                  : gray600,
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
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 6),
                            _buildInputField(_regFullNameController,
                                'Ví dụ: Nguyễn Mạnh Đức'),
                            const SizedBox(height: 14),

                            // Field 2: SỐ ĐIỆN THOẠI LIÊN HỆ
                            const Text(
                              'SỐ ĐIỆN THOẠI LIÊN HỆ',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 6),
                            _buildInputField(
                                _regPhoneController, 'Ví dụ: 0987654321',
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 14),

                            // Field 3: TÊN ĐĂNG NHẬP
                            const Text(
                              'TÊN ĐĂNG NHẬP',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 6),
                            _buildInputField(_regUsernameController,
                                'Nhập tài khoản mong muốn'),
                            const SizedBox(height: 14),

                            // Field 4: MẬT KHẨU BẢO MẬT
                            const Text(
                              'MẬT KHẨU BẢO MẬT',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 6),
                            _buildInputField(_regPasswordController,
                                'Nhập mật khẩu dài từ 6 ký tự',
                                obscureText: _obscureRegPassword),
                            const SizedBox(height: 14),

                            // Field 5: XÁC NHẬN MẬT KHẨU
                            const Text(
                              'XÁC NHẬN MẬT KHẨU',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: gray700,
                                  letterSpacing: 0.02),
                            ),
                            const SizedBox(height: 6),
                            _buildInputField(_regConfirmPasswordController,
                                'Nhập lại mật khẩu để xác thực',
                                obscureText: _obscureRegPassword),
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
                            backgroundColor: primaryDark,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'Đăng ký tài khoản',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Footer Link: Đã có tài khoản? Đăng nhập
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ',
                              style: TextStyle(fontSize: 13.5, color: gray600)),
                          GestureDetector(
                            onTap: () => setState(() =>
                                _viewState = 1), // Switch back to login screen
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: primaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
        style: const TextStyle(
            fontSize: 13.5, color: gray900, fontWeight: FontWeight.w600),
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
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: gray900),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                          border: Border.all(
                              color: primaryBlue.withValues(alpha: 0.2),
                              width: 2),
                        ),
                        child: const Icon(Icons.sms_rounded,
                            color: primaryBlue, size: 38),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nhập mã xác thực',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: gray900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mã OTP 6 chữ số đã được gửi đến\n${_pendingPhone ?? ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: gray600, height: 1.5),
                      ),

                      // Demo hint – only shown in debug
                      if (_pendingOtpPreview != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Text(
                                'Demo – Mã OTP: $_pendingOtpPreview',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309)),
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
                          hintStyle: const TextStyle(
                              letterSpacing: 8,
                              color: Color(0xFFCBD5E1),
                              fontSize: 24),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: gray200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: primaryBlue, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Countdown timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            expired
                                ? Icons.timer_off_rounded
                                : Icons.timer_outlined,
                            size: 16,
                            color: expired ? accentRed : gray600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expired
                                ? 'Mã OTP đã hết hạn'
                                : 'Mã hết hạn sau $timeStr',
                            style: TextStyle(
                              fontSize: 13,
                              color: expired ? accentRed : gray600,
                              fontWeight:
                                  expired ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (!expired && !_isLoading)
                              ? _handleOtpVerify
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: gray200,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_user_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xác nhận OTP',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
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
                                final result =
                                    await OtpService.instance.sendOtp(phone);
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
                        label: const Text('Gửi lại mã OTP',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style:
                            TextButton.styleFrom(foregroundColor: primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTrustItem extends StatelessWidget {
  const _LoginTrustItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8FD3C7), size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
