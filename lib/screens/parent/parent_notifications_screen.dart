import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/notification_service.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    // Filter children for the logged-in parent
    final myChildren = store.children.where((child) {
      if (user == null) return true;
      if (user.username == 'parent.demo') return true;
      final parentName = user.fullName.toLowerCase().trim();
      final motherName = child.motherName.toLowerCase().trim();
      return (parentName.isNotEmpty && motherName.contains(parentName)) ||
          (user.phone.isNotEmpty && child.motherPhone == user.phone);
    }).toList();

    final lateChildren = myChildren.where((c) => c.status == ChildVaccinationStatus.late).toList();
    final dueSoonChildren = myChildren.where((c) => c.status == ChildVaccinationStatus.dueSoon).toList();

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── Top Offline Bar ──────────────────────────────
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
                      : 'CHẾ ĐỘ NGOẠI TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "Sẵn sàng xem thông báo"}',
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

          // ── Header Bar ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 40, bottom: 12, left: 16, right: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tin tức & Thông báo Y tế',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: gray900),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: primaryBlue, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: gray200),

          // ── Main Content ListView ──────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                final sysNotifs = NotificationService.instance.notifications
                    .where((n) => n.priority == NotificationPriority.urgent || n.priority == NotificationPriority.warning)
                    .take(5)
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── 0. THÔNG BÁO HỆ THỐNG (from NotificationService) ──
                    if (sysNotifs.isNotEmpty) ...[
                      Row(
                        children: [
                          const Expanded(child: SectionLabel('THÔNG BÁO NHẮC TIÊM TỰ HỆ THỐNG')),
                          TextButton(
                            onPressed: () {
                              NotificationService.instance.markAllAsRead();
                              setState(() {});
                            },
                            child: const Text('Đã đọc hết', style: TextStyle(fontSize: 11, color: primaryBlue)),
                          ),
                        ],
                      ),
                      ...sysNotifs.map((n) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.white : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: n.isRead ? gray200 : const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              n.priority == NotificationPriority.urgent ? Icons.notification_important_rounded : Icons.notifications_active_rounded,
                              color: n.priority == NotificationPriority.urgent ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: gray900)),
                                  const SizedBox(height: 3),
                                  Text(n.body, style: const TextStyle(fontSize: 12, color: gray600, height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')} ${n.timestamp.day}/${n.timestamp.month}',
                                    style: const TextStyle(fontSize: 10, color: gray400),
                                  ),
                                ],
                              ),
                            ),
                            if (!n.isRead)
                              GestureDetector(
                                onTap: () {
                                  NotificationService.instance.markAsRead(n.id);
                                  setState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.check_circle_outline_rounded, size: 18, color: primaryBlue),
                                ),
                              ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                    ],

                    // ── 1. CẢNH BẢO TRỄ LỊCH TIÊM (red panel) ───────
                    if (lateChildren.isNotEmpty) ...[
                  const SectionLabel('CẢNH BÁO TRỄ LỊCH TIÊM CỦA CON'),
                  ...lateChildren.map((c) => _NotificationTile(
                        child: c,
                        type: _NotifType.late,
                      )),
                  const SizedBox(height: 12),
                ],

                // ── 2. NHẮC LỊCH TIÊM SẮP ĐẾN HẠN (yellow panel) ─
                if (dueSoonChildren.isNotEmpty) ...[
                  const SectionLabel('NHẮC LỊCH TIÊM SẮP ĐẾN HẠN'),
                  ...dueSoonChildren.map((c) => _NotificationTile(
                        child: c,
                        type: _NotifType.dueSoon,
                      )),
                  const SizedBox(height: 12),
                ],

                // ── 3. HOẠT ĐỘNG KHUYẾN KHÍCH TIÊM PHÒNG NGỪA ──
                const SectionLabel('HOẠT ĐỘNG KHUYẾN KHÍCH TIÊM PHÒNG NGỪA'),
                _buildNewsCard(
                  icon: Icons.campaign_rounded,
                  iconColor: primaryBlue,
                  iconBg: blueLight,
                  tag: 'CHIẾN DỊCH QUỐC GIA',
                  title: 'Chiến dịch Tiêm chủng vắc-xin Sởi – Rubella mở rộng 2026',
                  content:
                      'Bộ Y tế tổ chức tiêm bổ sung vắc-xin miễn phí cho tất cả trẻ từ 1 đến 5 tuổi tại các trạm y tế xã và điểm tiêm lưu động tại bản. Đưa trẻ đi tiêm phòng giúp nâng cao miễn dịch cộng đồng!',
                  time: 'Hôm nay · Trạm Y tế xã Tả Phìn',
                ),
                const SizedBox(height: 10),
                _buildNewsCard(
                  icon: Icons.verified_user_rounded,
                  iconColor: primaryDark,
                  iconBg: primaryLight,
                  tag: 'KHUYẾN CÁO Y TẾ',
                  title: 'Tại sao cần đưa trẻ đi tiêm vắc-xin đúng lịch?',
                  content:
                      'Tiêm vắc-xin đúng lịch giúp cơ thể trẻ sản sinh đủ kháng thể phòng bệnh sớm nhất, ngăn ngừa các biến chứng nguy hiểm như suy hô hấp, tiêu chảy cấp hay sốt cao.',
                  time: 'Được tham vấn bởi Y sĩ Lê Thu',
                ),
                const SizedBox(height: 10),
                _buildNewsCard(
                  icon: Icons.location_on_rounded,
                  iconColor: accentYellow,
                  iconBg: yellowLight,
                  tag: 'LỊCH TIÊM LƯU ĐỘNG',
                  title: 'Lịch tiêm lưu động tại Bản Nậm Lùng & Bản Cát Cát',
                  content:
                      'Đội y tế lưu động sẽ thăm khám và tiêm chủng trực tiếp tại Nhà văn hóa Bản Nậm Lùng từ 08h00 - 11h30 ngày 12/08/2026. Phụ huynh vui lòng mang theo Sổ tiêm chủng của con.',
                  time: '12/08/2026 · Đội Y tế Lưu động',
                ),
                const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String tag,
    required String title,
    required String content,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: gray900, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: gray600, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: gray400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
    final statusColor = isLate ? accentRed : accentYellow;
    final bgBorderColor = isLate ? redLight : yellowLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgBorderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgBorderColor, shape: BoxShape.circle),
            child: Icon(
              isLate ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLate ? 'Cảnh báo: ${child.fullName} trễ lịch tiêm!' : 'Nhắc lịch: ${child.fullName} sắp đến ngày tiêm!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: statusColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mũi tiêm: ${child.nextVaccine} · Dự kiến: ${formatDate(child.nextDue)}',
                  style: const TextStyle(fontSize: 11.5, color: gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
