import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'parent_child_detail_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String _selectedFilter = 'all'; // 'all', 'late', 'complete'

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;

    final parentName = user?.fullName ?? 'Mẹ Nguyễn Thị Lan';

    // Get children for this parent or default demo children
    final children = store.children.where((child) {
      if (user == null) return true;
      if (user.username == 'parent.demo') return true;
      final pName = user.fullName.toLowerCase().trim();
      final mName = child.motherName.toLowerCase().trim();
      return (pName.isNotEmpty && mName.contains(pName)) ||
          (user.phone.isNotEmpty && child.motherPhone == user.phone);
    }).toList();

    final lateChildren = children.where((c) => c.lateDays > 0).toList();
    final hasLateChild = lateChildren.isNotEmpty;
    final lateChild = hasLateChild ? lateChildren.first : null;

    // Filter children based on selected tab filter
    final filteredChildren = children.where((c) {
      if (_selectedFilter == 'late') return c.lateDays > 0;
      if (_selectedFilter == 'complete') return c.lateDays <= 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── 1. Top Offline Alert Banner (Brown/Orange) ────────
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

          // ── 2. Header Title Bar ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 40, bottom: 12, left: 16, right: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: primaryDark, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sổ Gia Đình Sổ sức khỏe',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: gray900),
                  ),
                ),
                // Notification bell icon
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

          // ── Main Scrollable Body ────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 3. Green Parent Card ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669), // Dark Emerald Green
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHỤ HUYNH BẢN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFA7F3D0),
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parentName.startsWith('Mẹ') || parentName.startsWith('Bố') ? parentName : 'Mẹ $parentName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gia đình đang theo dõi sổ tiêm của ${children.length} con',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Passport QR pill button
                      GestureDetector(
                        onTap: () {
                          if (children.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ParentChildDetailScreen(childId: children.first.id),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Hộ chiếu tiêm chủng (QR)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 3.5. Detailed Vaccination Alert & Guidance Card (ĐỊA ĐIỂM & THỜI GIAN TIÊM) ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasLateChild ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: hasLateChild ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasLateChild ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                            color: hasLateChild ? const Color(0xFFDC2626) : primaryBlue,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasLateChild
                                  ? 'CẢNH BÁO TRỄ TIÊM & HƯỚNG DẪN ĐI TIÊM'
                                  : 'HƯỚNG DẪN ĐỊA ĐIỂM & THỜI GIAN TIÊM CHỦNG',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: hasLateChild ? const Color(0xFFDC2626) : primaryBlue,
                                letterSpacing: 0.02,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (hasLateChild && lateChild != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '⚠️ Trẻ ${lateChild.fullName} đang bị trễ ${lateChild.lateDays} ngày mũi tiêm ${lateChild.nextVaccine}. Đề nghị phụ huynh mang theo sổ tiêm để tiêm bổ sung ngay!',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      Container(height: 1, color: hasLateChild ? const Color(0xFFFECACA) : const Color(0xFFDBEAFE)),
                      const SizedBox(height: 10),
                      _guidanceRow(
                        icon: Icons.location_on_outlined,
                        title: 'Địa điểm tiêm:',
                        content: 'Trạm Y tế xã Tả Phìn (hoặc Nhà văn hóa Bản Nậm Lùng đối với điểm tiêm lưu động)',
                      ),
                      const SizedBox(height: 8),
                      _guidanceRow(
                        icon: Icons.access_time_rounded,
                        title: 'Thời gian tiêm:',
                        content: 'Sáng thứ 2 đến thứ 6 (07h30 – 11h00). Lịch tiêm tập trung: Ngày 10 và 12 hàng tháng.',
                      ),
                      const SizedBox(height: 8),
                      _guidanceRow(
                        icon: Icons.assignment_outlined,
                        title: 'Giấy tờ mang theo:',
                        content: 'Sổ tiêm chủng cá nhân của trẻ & Mã QR hồ sơ trên ứng dụng',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 4. SỔ TIÊM & LỊCH CỦA CÁC CON ───────────────
                const SectionLabel('SỔ TIÊM & LỊCH CỦA CÁC CON'),

                // Filter chips row
                Row(
                  children: [
                    _buildFilterChip('Tất cả con', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Trễ hẹn', 'late'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã tiêm đủ', 'complete'),
                  ],
                ),
                const SizedBox(height: 12),

                // Children Card List
                if (filteredChildren.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gray200),
                    ),
                    child: const Center(
                      child: Text('Không có dữ liệu con trong danh mục này.', style: TextStyle(color: gray500, fontSize: 13)),
                    ),
                  )
                else
                  ...filteredChildren.map((child) => _buildChildCard(context, child)),

                const SizedBox(height: 16),

                // ── 5. Alert Box: CHƯA XÁC ĐỊNH - DỮ LIỆU CHƯA ĐỒNG BỘ ─────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'CHƯA XÁC ĐỊNH - DỮ LIỆU CHƯA ĐỒNG BỘ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF475569),
                                letterSpacing: 0.03,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hệ thống phát hiện có dữ liệu tiêm chủng ngoại tuyến chưa được đồng bộ đầy đủ lên Cloud. Vui lòng bấm đồng bộ từ máy Cán bộ y tế để cập nhật trạng thái chính xác.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ],
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

  Widget _guidanceRow({required IconData icon, required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: gray700),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: gray900),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(fontSize: 12, color: gray700, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryBlue : gray200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : gray700,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildProfile child) {
    final isLate = child.lateDays > 0;
    final pillBg = isLate ? redLight : primaryLight;
    final pillFg = isLate ? accentRed : primaryDark;
    final pillText = isLate ? 'Trễ ${child.lateDays} ngày' : 'Đã tiêm đủ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ParentChildDetailScreen(childId: child.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    child.fullName.characters.first,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: gray900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lịch tiêm: ${child.nextVaccine}',
                      style: const TextStyle(color: gray500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pillText,
                  style: TextStyle(color: pillFg, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
