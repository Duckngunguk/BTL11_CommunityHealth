import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    String roleLabel = 'Cán bộ y tế';
    if (user?.role == UserRole.admin) {
      roleLabel = 'Quản trị viên';
    } else if (user?.role == UserRole.parent) {
      roleLabel = 'Phụ huynh';
    }

    final stationText = user?.assignedCommune != null
        ? 'Trạm Y tế xã ${user!.assignedCommune}'
        : 'Trạm Y tế xã Tả Phìn';

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 48, bottom: 0),
          child: const Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cài đặt',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: gray900),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: gray200),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Profile Card ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gray200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: blueLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Y sĩ Lê Thu',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: gray900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stationText · $roleLabel',
                      style: const TextStyle(color: gray500, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Cài đặt chung ─────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'CÀI ĐẶT CHUNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: gray500,
              letterSpacing: 0.05,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gray200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              _buildSettingRow(
                title: 'Tự động đồng bộ',
                subtitle: 'Khi thiết bị có Wi-Fi hoặc dữ liệu di động',
                trailing: Switch.adaptive(
                  value: true,
                  activeThumbColor: primaryDark,
                  onChanged: (_) {},
                ),
              ),
              _divider(),
              _buildSettingRow(
                title: 'Nhắc lịch tiêm',
                subtitle: 'Hiển thị nhắc lịch trên thiết bị',
                trailing: Switch.adaptive(
                  value: true,
                  activeThumbColor: primaryDark,
                  onChanged: (_) {},
                ),
              ),
              _divider(),
              _buildSettingRow(
                title: 'Mã hóa dữ liệu cục bộ',
                subtitle: 'Bảo vệ dữ liệu bằng AES-256',
                trailing: const Icon(Icons.check_circle_rounded,
                    color: primaryDark, size: 20),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Thông tin hệ thống ────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'THÔNG TIN HỆ THỐNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: gray500,
              letterSpacing: 0.05,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gray200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              _buildSettingRow(
                title: 'Phiên bản',
                trailing: const Text('1.0.0 Demo',
                    style: TextStyle(color: gray500, fontSize: 12.5)),
              ),
              _divider(),
              _buildSettingRow(
                title: 'Mã thiết bị',
                trailing: const Text('CH-DEV-001',
                    style: TextStyle(
                        color: gray500,
                        fontSize: 12.5,
                        fontFamily: 'monospace')),
              ),
              _divider(),
              // Đăng xuất
              GestureDetector(
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: accentRed, size: 18),
                      SizedBox(width: 10),
                      Text('Đăng xuất',
                          style: TextStyle(
                              color: accentRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
      height: 1, color: gray100, margin: const EdgeInsets.only(left: 14));

  Widget _buildSettingRow({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final vPad = subtitle != null ? 10.0 : 13.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: gray900)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11.5, color: gray500)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
