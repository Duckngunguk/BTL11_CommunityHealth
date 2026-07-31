import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';

enum AppMode { mobile, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AppMode> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'healthworker.demo');
  final _passwordController = TextEditingController(text: '123456');
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
                                'Dữ liệu demo được lưu cục bộ để mô phỏng khả năng hoạt động ngoại tuyến.',
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
                                onPressed: () => widget.onLogin(AppMode.mobile),
                                icon: const Icon(Icons.phone_android_rounded),
                                label: const Text('Vào Mobile App'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => widget.onLogin(AppMode.admin),
                                icon: const Icon(Icons.dashboard_outlined),
                                label: const Text('Mở Web Admin'),
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 17, color: Colors.black45),
                                  SizedBox(width: 6),
                                  Text('Có thể đăng nhập bằng dữ liệu đã cache', style: TextStyle(color: Colors.black54)),
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
