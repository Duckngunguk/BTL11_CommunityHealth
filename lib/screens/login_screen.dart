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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị màn hình đăng ký nếu user click "Đăng ký"
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (wide)
                Expanded(
                  child: Container(
                    color: primaryGreen,
                    padding: const EdgeInsets.all(56),
                    child: const _BrandPanel(),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!wide) ...[
                                const Icon(Icons.health_and_safety_rounded, size: 54, color: primaryGreen),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                'Đăng nhập CommunityHealth',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Nhập tài khoản bên dưới để đăng nhập.',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên đăng nhập',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded),
                                          SizedBox(width: 8),
                                          Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 20),
                              const Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 17, color: Colors.black45),
                                  SizedBox(width: 6),
                                  Text('Hỗ trợ đăng nhập với dữ liệu đã lưu ngoại tuyến', style: TextStyle(color: Colors.black54, fontSize: 13), textAlign: TextAlign.center),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              // Nút Đăng ký tài khoản mới
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.black54)),
                                  GestureDetector(
                                    onTap: () => setState(() => _showRegister = true),
                                    child: const Text(
                                      'Đăng ký ngay',
                                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
    // Giả lập độ trễ xác thực REST API (400ms)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final store = AppScope.of(context);

    // Kiểm tra tài khoản trong hệ thống
    final user = store.users.where((u) => u.username.toLowerCase() == username).firstOrNull;

    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản chưa được đăng ký trong hệ thống. Vui lòng bấm "Đăng ký ngay"!'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return;
    }

    if (user.password != null && user.password!.isNotEmpty && user.password != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không chính xác. Vui lòng thử lại!'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return;
    }

    if (user.status == UserAccountStatus.pendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản đang chờ Admin phê duyệt. Vui lòng thử lại sau.'),
          backgroundColor: Color(0xFF8A5D00),
        ),
      );
      return;
    }

    if (user.status == UserAccountStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản đã bị khóa. Vui lòng liên hệ Quản trị viên.'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return;
    }

    // Lưu currentUser vào AppStore
    store.currentUser = user;
    store.addAuditLog('Đăng nhập hệ thống', 'Đăng nhập thành công từ ứng dụng');

    // Route theo vai trò
    if (user.role == UserRole.admin) {
      widget.onLogin(AppMode.admin);
    } else if (user.role == UserRole.parent) {
      widget.onLogin(AppMode.parent);
    } else {
      widget.onLogin(AppMode.mobile);
    }
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.health_and_safety_rounded, color: primaryGreen, size: 42),
        ),
        const SizedBox(height: 28),
        const Text(
          'CommunityHealth',
          style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sổ tay tiêm chủng ngoại tuyến và giám sát dịch tễ vùng sâu.',
          style: TextStyle(color: Colors.white70, fontSize: 19, height: 1.5),
        ),
        const SizedBox(height: 34),
        const _FeatureLine(icon: Icons.cloud_off_rounded, text: 'Tra cứu và ghi nhận tiêm khi không có mạng'),
        const _FeatureLine(icon: Icons.sync_rounded, text: 'Đồng bộ an toàn khi kết nối trở lại'),
        const _FeatureLine(icon: Icons.analytics_outlined, text: 'Theo dõi tỷ lệ phủ vaccine theo từng xã'),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}
