import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                'Nhập tài khoản bên dưới để đăng nhập. Mỗi tài khoản có vai trò riêng trong hệ thống.',
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
                              FilledButton.icon(
                                onPressed: _handleLogin,
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD0DCE5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gợi ý tài khoản demo:',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ActionChip(
                                          avatar: const Icon(Icons.person_outline_rounded, size: 16),
                                          label: const Text('Cán bộ y tế', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            setState(() {
                                              _usernameController.text = 'healthworker.demo';
                                              _passwordController.text = '123456';
                                            });
                                          },
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.family_restroom_rounded, size: 16),
                                          label: const Text('Phụ huynh', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            setState(() {
                                              _usernameController.text = 'parent.demo';
                                              _passwordController.text = '123456';
                                            });
                                          },
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                                          label: const Text('Quản trị viên', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            setState(() {
                                              _usernameController.text = 'admin.demo';
                                              _passwordController.text = '123456';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 17, color: Colors.black45),
                                  SizedBox(width: 6),
                                  Text('Hỗ trợ đăng nhập với dữ liệu đã lưu ngoại tuyến', style: TextStyle(color: Colors.black54, fontSize: 13)),
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

  void _handleLogin() {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập')),
      );
      return;
    }

    if (username.contains('admin')) {
      widget.onLogin(AppMode.admin);
    } else if (username.contains('parent') || username.contains('phuHuynh') || username.contains('phuhuynh')) {
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
