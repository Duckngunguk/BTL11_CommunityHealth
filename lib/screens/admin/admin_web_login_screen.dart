import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class AdminWebLoginScreen extends StatefulWidget {
  const AdminWebLoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSwitchToMobileLogin,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onSwitchToMobileLogin;

  @override
  State<AdminWebLoginScreen> createState() => _AdminWebLoginScreenState();
}

class _AdminWebLoginScreenState extends State<AdminWebLoginScreen> {
  final _usernameController = TextEditingController(text: 'admin.demo');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vui lòng nhập đầy đủ Tên đăng nhập và Mật khẩu Quản trị!')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Không thể đăng nhập.'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    if (response.data!.role != UserRole.admin) {
      await store.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ Tài khoản không có quyền Quản trị viên Web!'),
          backgroundColor: accentRed,
        ),
      );
      return;
    }

    await store.addAuditLog(
      'Đăng nhập Web Admin',
      'Đăng nhập vào Cổng Quản trị Web thành công',
    );
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // ── Web Portal Top Bar ──────────────────────────────
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                const AppLogo(size: 38),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onSwitchToMobileLogin,
                  icon: const Icon(Icons.smartphone_rounded,
                      size: 16, color: gray500),
                  label: const Text(
                    'Chuyển sang Ứng dụng Di động',
                    style: TextStyle(color: gray600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 460),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: gray200),
                    boxShadow: const [
                      appSurfaceShadow,
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: isDesktop
                        ? Row(
                            children: [
                              // Left Hero Panel
                              Expanded(child: _buildHeroPanel()),
                              // Right Login Card
                              Expanded(child: _buildFormPanel()),
                            ],
                          )
                        : _buildFormPanel(),
                  ),
                ),
              ),
            ),
          ),

          // ── Web Footer ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              '© 2026 CommunityHealth · Trung tâm Y tế thị xã Sa Pa',
              style: TextStyle(color: gray500, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        color: Color(0xFF123C3A),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hệ thống Quản trị & Giám sát Tiêm chủng',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'Báo cáo dịch tễ thời gian thực, quản lý bao phủ vắc-xin, điều phối lực lượng y tế lưu động toàn huyện Sa Pa.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFFB9D8D2), height: 1.5),
          ),
          const SizedBox(height: 32),
          _featureRow(
              Icons.verified_user_outlined, 'Phân quyền tài khoản y tế xã/bản'),
          const SizedBox(height: 10),
          _featureRow(Icons.map_outlined, 'Bản đồ giám sát ca bệnh nghi ngờ'),
          const SizedBox(height: 10),
          _featureRow(
              Icons.cloud_sync_outlined, 'Đồng bộ dữ liệu Firebase Cloud'),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8FD3C7), size: 18),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFormPanel() {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: blueLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.security_rounded,
                    color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đăng nhập Web Admin',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: gray900)),
                  Text('Dành cho Quản trị viên Trung tâm Y tế',
                      style: TextStyle(fontSize: 11.5, color: gray500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Form fields
          const Text('TÀI KHOẢN QUẢN TRỊ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gray600,
                  letterSpacing: 0.04)),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 13.5, color: gray900),
            decoration: const InputDecoration(
              hintText: 'Nhập tên đăng nhập admin',
              prefixIcon:
                  Icon(Icons.person_outline_rounded, size: 18, color: gray400),
            ),
          ),
          const SizedBox(height: 16),

          const Text('MẬT KHẨU',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gray600,
                  letterSpacing: 0.04)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            style: const TextStyle(fontSize: 13.5, color: gray900),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 18, color: gray400),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: gray500),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleAdminLogin,
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Truy cập Cổng Quản trị',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: gray100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gray200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: gray600),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tài khoản mặc định: admin.demo / 123456',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: gray600,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
