import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool _smsEnabled = true;
  bool _alertEnabled = true;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;
    final parentName = user?.fullName ?? 'Mẹ Nguyễn Thị Lan';
    final phone = user?.phone.isNotEmpty == true ? user!.phone : '0987654321';

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── 1. Top Status Bar (Offline bar) ───────────────
          Container(
            color: const Color(0xFFB06000),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  store.isOnline
                      ? 'CHẾ ĐỘ TRỰC TUYẾN • ĐÃ ĐỒNG BỘ'
                      : 'CHẾ ĐỘ NGOẠI TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "Sẵn sàng xem dữ liệu"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Header Bar ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 40, bottom: 12, left: 16, right: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cài đặt gia đình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: gray900),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined, color: primaryDark, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: gray200),

          // ── Main Content ──────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 3. Parent Profile Card ──────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gray200),
                  ),
                  child: Row(
                    children: [
                      // Avatar circle "NL"
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7), // Light green
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'NL',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: gray900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Gia đình Bản Cát Cát • Mã hộ: GD-8899',
                              style: TextStyle(fontSize: 12, color: gray500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 4. THÔNG TIN HỘ GIA ĐÌNH ────────────────────
                const SectionLabel('THÔNG TIN HỘ GIA ĐÌNH'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gray200),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Chủ hộ gia đình', 'Nguyễn Văn Bính (Chồng)'),
                      const Divider(height: 1, color: gray100, indent: 16),
                      _infoRow('Địa chỉ đăng ký', 'Bản Nậm Lùng, xã Tả Phìn'),
                      const Divider(height: 1, color: gray100, indent: 16),
                      _infoRow('Số điện thoại liên hệ', phone),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 5. CẤU HÌNH NHẬN THÔNG BÁO ────────────────
                const SectionLabel('CẤU HÌNH NHẬN THÔNG BÁO'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gray200),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'SMS nhắc tiêm chủng',
                                style: TextStyle(fontSize: 13.5, color: gray700, fontWeight: FontWeight.w500),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _smsEnabled = !_smsEnabled),
                              child: Text(
                                _smsEnabled ? 'Đã Bật' : 'Đã Tắt',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _smsEnabled ? const Color(0xFF16A34A) : gray400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: gray100, indent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Cảnh báo dịch địa phương',
                                style: TextStyle(fontSize: 13.5, color: gray700, fontWeight: FontWeight.w500),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _alertEnabled = !_alertEnabled),
                              child: Text(
                                _alertEnabled ? 'Đã Bật' : 'Đã Tắt',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _alertEnabled ? const Color(0xFF16A34A) : gray400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 6. HƯỚNG DẪN SỬ DỤNG & HỖ TRỢ ────────────────
                const SectionLabel('HƯỚNG DẪN SỬ DỤNG & HỖ TRỢ'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gray200),
                  ),
                  child: Column(
                    children: [
                      _guideRow(
                        icon: Icons.qr_code_2_rounded,
                        title: 'Mã QR Hộ chiếu tiêm chủng',
                        subtitle: 'Mở mã QR cá nhân cho Cán bộ y tế quét khi đến điểm tiêm để ghi nhận mũi tiêm nhanh chóng.',
                      ),
                      const Divider(height: 1, color: gray100, indent: 16),
                      _guideRow(
                        icon: Icons.calendar_month_rounded,
                        title: 'Theo dõi lịch tiêm & trễ hạn',
                        subtitle: 'Kiểm tra trạng thái màu sắc: Xanh (Đã tiêm đủ), Đỏ (Trễ tiêm cần đưa trẻ đi tiêm bổ sung).',
                      ),
                      const Divider(height: 1, color: gray100, indent: 16),
                      _guideRow(
                        icon: Icons.phone_in_talk_rounded,
                        title: 'Hotline Y tế xã Tả Phìn',
                        subtitle: 'Tổng đài hỗ trợ: 0214 387 1115 (Trạm Y tế xã Tả Phìn, huyện Sa Pa).',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── 7. Red Logout Button ────────────────────────
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: widget.onLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // Solid Red
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideRow({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: blueLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: gray900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: gray600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: gray600, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: gray900, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
