import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    // Filter children strictly for the logged-in parent
    final myChildren = store.children.where((child) {
      if (user == null) return true;
      if (user.username == 'parent.demo') {
        return child.motherName.contains('Giàng A Sáng') || child.motherName.contains('Giàng');
      }
      final parentName = user.fullName.toLowerCase().trim();
      final motherName = child.motherName.toLowerCase().trim();
      return (parentName.isNotEmpty && motherName.contains(parentName)) ||
          (user.phone.isNotEmpty && child.motherPhone == user.phone);
    }).toList();

    final lateChildren = myChildren.where((c) => c.status == ChildVaccinationStatus.late).toList();
    final dueSoonChildren = myChildren.where((c) => c.status == ChildVaccinationStatus.dueSoon).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thông tin tài khoản thực tế
        _AccountCard(user: user, onLogout: onLogout),
        const SizedBox(height: 20),

        // Thông báo trễ lịch
        if (lateChildren.isNotEmpty) ...[
          const SectionHeader(
            title: '🚨 Cảnh báo trễ lịch tiêm',
            subtitle: 'Các trẻ cần đi tiêm ngay.',
          ),
          const SizedBox(height: 10),
          ...lateChildren.map((c) => _NotificationTile(
                child: c,
                type: _NotifType.late,
              )),
          const SizedBox(height: 20),
        ],

        // Thông báo sắp đến hạn
        if (dueSoonChildren.isNotEmpty) ...[
          const SectionHeader(
            title: '🔔 Nhắc lịch tiêm sắp đến',
            subtitle: 'Chuẩn bị đưa con đến trạm y tế.',
          ),
          const SizedBox(height: 10),
          ...dueSoonChildren.map((c) => _NotificationTile(
                child: c,
                type: _NotifType.dueSoon,
              )),
          const SizedBox(height: 20),
        ],

        // Không có thông báo
        if (lateChildren.isEmpty && dueSoonChildren.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              title: 'Không có thông báo mới',
              description: 'Các con của bạn đang có lịch tiêm tốt. Hãy tiếp tục theo dõi định kỳ!',
            ),
          ),

        const SizedBox(height: 16),

        // Hướng dẫn phụ huynh
        const _GuideCard(),
      ],
    );
  }
}

enum _NotifType { late, dueSoon }

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.child, required this.type});
  final ChildProfile child;
  final _NotifType type;

  @override
  Widget build(BuildContext context) {
    final isLate = type == _NotifType.late;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLate ? const Color(0xFFFFE9E7) : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isLate ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
                color: isLate ? const Color(0xFFB42318) : const Color(0xFF8A5D00),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLate
                        ? 'Trễ ${child.lateDays} ngày - ${child.nextVaccine}'
                        : 'Đến hạn ngày ${formatDate(child.nextDue)} - ${child.nextVaccine}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isLate ? const Color(0xFFB42318) : const Color(0xFF8A5D00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${child.village}, ${child.commune}',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.onLogout});
  final UserModel? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tài khoản của bạn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.account_circle_outlined, size: 18, color: Colors.black45),
                const SizedBox(width: 8),
                Text(
                  user?.fullName != null ? '${user!.fullName} (@${user!.username})' : (user?.username ?? 'phuhuynh'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  'Vai trò: ${user?.role == UserRole.parent ? "Phụ huynh" : "Thành viên"}',
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if ((user?.phone ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Colors.black45),
                  const SizedBox(width: 8),
                  Text('SĐT: ${user!.phone}', style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    const guideItems = [
      '• Kiểm tra hồ sơ con thường xuyên để không bỏ lỡ lịch tiêm.',
      '• Liên hệ trạm y tế xã/phường nếu con bị trễ lịch tiêm.',
      '• Thông tin trên đây do cán bộ y tế cập nhật và xác minh.',
      '• Mã QR của con được dùng để cán bộ tra cứu nhanh hồ sơ.',
    ];

    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Hướng dẫn dành cho phụ huynh',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...guideItems.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1B5E20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
