import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common_widgets.dart';

typedef OnBackToLoginWithUser = void Function([String? registeredUsername]);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBackToLogin});

  final OnBackToLoginWithUser onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _communeController = TextEditingController(text: 'Tả Phìn');
  final _secretCodeController = TextEditingController();

  UserRole _selectedRole = UserRole.healthWorker;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _communes = ['Tả Phìn', 'Hầu Thào', 'San Sả Hồ', 'Tả Van', 'Lao Chải', 'Bản Hồ'];

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _communeController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 36 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => widget.onBackToLogin(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đăng ký tài khoản',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Tạo tài khoản mới cho ứng dụng di động CommunityHealth',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // Chọn vai trò
                      const Text(
                        'Chọn loại tài khoản (App Mobile):',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment<UserRole>(
                            value: UserRole.healthWorker,
                            icon: Icon(Icons.badge_outlined),
                            label: Text('Cán bộ Y tế'),
                          ),
                          ButtonSegment<UserRole>(
                            value: UserRole.parent,
                            icon: Icon(Icons.family_restroom_rounded),
                            label: Text('Phụ huynh'),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (val) {
                          setState(() {
                            _selectedRole = val.first;
                            _secretCodeController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tên đăng nhập & Họ tên
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'Ví dụ: ysi.lethu',
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                          if ((v ?? '').trim().length < 4) return 'Ít nhất 4 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên người dùng *',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: 'Ví dụ: Lê Thị Thu',
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email & Điện thoại
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Bắt buộc';
                                if (!v!.contains('@')) return 'Email không hợp lệ';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại *',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_selectedRole == UserRole.healthWorker) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _communeController.text,
                          decoration: const InputDecoration(
                            labelText: 'Xã phụ trách *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          items: _communes.map((c) => DropdownMenuItem(value: c, child: Text('Xã $c'))).toList(),
                          onChanged: (val) {
                            if (val != null) _communeController.text = val;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _secretCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Mã xác thực Cán bộ Y tế *',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                            hintText: 'Mã thử nghiệm: YTE2026',
                          ),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Vui lòng nhập mã xác thực Cán bộ Y tế';
                            if (v!.trim() != 'YTE2026') return 'Mã xác thực Y tế không hợp lệ (Mã thử nghiệm: YTE2026)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Mật khẩu & Nhập lại mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v!.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Xác nhận mật khẩu *',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút đăng ký
                      FilledButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'ĐĂNG KÝ TÀI KHOẢN',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ', style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800),
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
    );
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final store = AppScope.of(context);

    final response = await store.registerUser(
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      password: _passwordController.text,
      assignedCommune: _selectedRole == UserRole.healthWorker ? _communeController.text : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.success) {
      final isPending = response.data?.isPending ?? false;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
            color: isPending ? const Color(0xFFD97706) : const Color(0xFF18794E),
            size: 48,
          ),
          title: Text(isPending ? 'Đăng ký thành công - Chờ Admin duyệt' : 'Đăng ký thành công!'),
          content: Text(response.message ?? 'Tài khoản của bạn đã được đăng ký.'),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isPending ? const Color(0xFFD97706) : const Color(0xFF18794E),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onBackToLogin(_usernameController.text.trim());
              },
              child: Text(isPending ? 'Quay lại Đăng nhập' : 'Đăng nhập ngay'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Đăng ký thất bại. Vui lòng thử lại.'),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    }
  }
}
