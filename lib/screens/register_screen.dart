import 'package:flutter/material.dart';

import '../state/app_store.dart';
import '../widgets/common_widgets.dart';

typedef OnBackToLoginWithUser = void Function([String? registeredEmail]);

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
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
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
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Tạo tài khoản mới cho ứng dụng di động CommunityHealth',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Đăng ký công khai chỉ dành cho Phụ huynh. Tài khoản cán bộ y tế do Admin tạo.',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                          if ((v ?? '').trim().isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập';
                          }
                          if ((v ?? '').trim().length < 4) {
                            return 'Ít nhất 4 ký tự';
                          }
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
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Vui lòng nhập họ tên'
                            : null,
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
                                if (!v!.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
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
                              validator: (v) =>
                                  (v ?? '').trim().isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mật khẩu & Nhập lại mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (v!.length < 6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }
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
                          if (v != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
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
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'ĐĂNG KÝ TÀI KHOẢN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ',
                              style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w800),
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

    final response = await store.registerParent(
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.success) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF18794E),
            size: 48,
          ),
          title: const Text('Đăng ký Phụ huynh thành công!'),
          content:
              Text(response.message ?? 'Tài khoản của bạn đã được đăng ký.'),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18794E)),
              onPressed: () {
                Navigator.pop(context);
                widget.onBackToLogin(_emailController.text.trim());
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(response.error ?? 'Đăng ký thất bại. Vui lòng thử lại.'),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    }
  }
}
