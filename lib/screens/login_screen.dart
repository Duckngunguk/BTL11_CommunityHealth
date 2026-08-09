import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';

enum AppMode { mobile, admin, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AppMode> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _obscure = true;
  bool _isLoading = false;
  bool _showRegister = false;

  // 0 = role selector, 1 = login form
  int _step = 0;
  String _selectedRole = 'cb'; // 'cb' hoặc 'ph'

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(
        onBackToLogin: ([registeredUsername]) {
          setState(() {
            _showRegister = false;
            if (registeredUsername != null && registeredUsername.isNotEmpty) {
              _usernameController.text = registeredUsername;
              _passwordController.clear();
            }
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: gray100,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _step == 0 ? _buildRoleSelector() : _buildLoginForm(),
        ),
      ),
    );
  }

  // ─── VIEW 1: Role Selector ─────────────────────────────────
  Widget _buildRoleSelector() {
    return Container(
      key: const ValueKey('role'),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.18),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 22),

            // Title
            const Text(
              'COMMUNITY HEALTH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
                letterSpacing: 0.03,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sổ tay tiêm chủng & Giám sát dịch bệnh',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: gray500, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 36),

            // Role button: Cán bộ Y tế
            // Role button 1: Cán bộ Y tế
            _buildRoleButton(
              icon: Icons.monitor_heart_outlined,
              iconColor: primaryBlue,
              iconBg: blueLight,
              title: 'Cán bộ Y tế',
              subtitle: 'Ghi nhận tiêm chủng, giám sát dịch bệnh',
              onTap: () {
                setState(() {
                  _selectedRole = 'cb';
                  _usernameController.text = 'healthworker.demo';
                  _passwordController.text = '123456';
                  _step = 1;
                });
              },
            ),
            const SizedBox(height: 12),

            // Role button 2: Phụ huynh
            _buildRoleButton(
              icon: Icons.family_restroom_rounded,
              iconColor: primaryDark,
              iconBg: primaryLight,
              title: 'Phụ huynh',
              subtitle: 'Theo dõi lịch tiêm của con, nhận thông báo',
              onTap: () {
                setState(() {
                  _selectedRole = 'ph';
                  _usernameController.text = 'parent.demo';
                  _passwordController.text = '123456';
                  _step = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gray200, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: gray900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: gray500, height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: gray400),
          ],
        ),
      ),
    );
  }

  // ─── VIEW 2: Login Form ─────────────────────────────────────
  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey('form'),
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _step = 0),
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left_rounded, color: primaryBlue, size: 22),
                      Text('Trở về', style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Đăng nhập',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: gray900),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo nhỏ
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gray200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        const Text('TÊN ĐĂNG NHẬP / SỐ ĐIỆN THOẠI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gray600, letterSpacing: 0.02)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(fontSize: 13, color: gray900),
                          decoration: const InputDecoration(
                            hintText: 'Nhập tài khoản của bạn',
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Password
                        const Text('MẬT KHẨU',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gray600, letterSpacing: 0.02)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          style: const TextStyle(fontSize: 13, color: gray900),
                          decoration: InputDecoration(
                            hintText: 'Nhập mật khẩu',
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18, color: gray500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Remember + Forgot
                        Row(
                          children: [
                            const Icon(Icons.check_box_outlined, size: 16, color: primaryDark),
                            const SizedBox(width: 4),
                            const Text('Ghi nhớ mật khẩu', style: TextStyle(fontSize: 12, color: gray700)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {},
                              child: const Text('Quên mật khẩu?',
                                  style: TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login + Biometric buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Đăng nhập tài khoản',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Biometric button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: blueLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryBlue, width: 1.5),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: primaryBlue, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? ', style: TextStyle(fontSize: 12.5, color: gray600)),
                      GestureDetector(
                        onTap: () => setState(() => _showRegister = true),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(fontSize: 12.5, color: primaryDark, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final store = AppScope.of(context);

    final user = store.users.where((u) => u.username.toLowerCase() == username).firstOrNull;

    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản chưa được đăng ký trong hệ thống. Vui lòng bấm "Đăng ký ngay"!'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    if (user.password != null && user.password!.isNotEmpty && user.password != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không chính xác. Vui lòng thử lại!'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    if (user.status == UserAccountStatus.pendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản đang chờ Admin phê duyệt. Vui lòng thử lại sau.'),
          backgroundColor: accentYellow,
        ),
      );
      return;
    }

    if (user.status == UserAccountStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản đã bị khóa. Vui lòng liên hệ Quản trị viên.'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    // Role security check
    if (_selectedRole == 'admin' && user.role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ Tài khoản này không có quyền Quản trị viên (Admin)!'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    store.currentUser = user;
    store.addAuditLog('Đăng nhập hệ thống', 'Đăng nhập thành công từ ứng dụng (${user.role.name})');

    if (user.role == UserRole.admin) {
      widget.onLogin(AppMode.admin);
    } else if (user.role == UserRole.parent) {
      widget.onLogin(AppMode.parent);
    } else {
      widget.onLogin(AppMode.mobile);
    }
  }
}
