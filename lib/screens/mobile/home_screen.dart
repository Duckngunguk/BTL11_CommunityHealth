import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/notification_service.dart';
import '../../services/report_export_service.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_detail_screen.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenChildren});

  final VoidCallback onOpenChildren;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedVillage = '';

  static const _villages = [
    '',
    'Bản Nậm Lùng',
    'Bản Sapa',
    'Bản Cát Cát',
    'Bản Tả Phìn',
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final userName = store.currentUser?.fullName ?? 'Y sĩ Lê Thu';
    final commune = store.currentUser?.assignedCommune ?? 'Tả Phìn';

    // Count children per village for chip labels
    final allChildren = store.children;
    final totalCount = allChildren.length;
    final namLungCount = allChildren.where((c) => c.village == 'Bản Nậm Lùng').length;
    final sapaCount = allChildren.where((c) => c.village == 'Bản Sapa').length;
    final catCatCount = allChildren.where((c) => c.village == 'Bản Cát Cát').length;

    // Filter children by village
    final scheduleList = allChildren.where((child) {
      final matchVillage = _selectedVillage.isEmpty || child.village == _selectedVillage;
      return matchVillage;
    }).toList();

    return Scaffold(
      backgroundColor: gray100,
      body: RefreshIndicator(
        color: primaryDark,
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 500)),
        child: CustomScrollView(
          slivers: [
            // ── 1. Top Offline Alert Banner (Matching Prototype) ──
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFB06000), // Dark yellow-orange bar
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
                          : 'CHẾ ĐỘ NGOẠI TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "Sẵn sàng ghi dữ liệu"}',
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
            ),

            // ── 2. Green Header Container ─────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF059669), // Dark emerald green
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  children: [
                    // Top row: LT Avatar + Name + Settings Icon
                    Row(
                      children: [
                        // Avatar circle "LT"
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'LT',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRẠM Y TẾ XÃ ${commune.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.04,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                userName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        // Settings Gear button
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('Cài đặt')),
                                body: SettingsScreen(onLogout: () => Navigator.of(context).pop()),
                              ),
                            ),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search input + QR button row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onOpenChildren,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search_rounded, color: gray400, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tra cứu phụ huynh, trẻ con...',
                                    style: TextStyle(fontSize: 12.5, color: gray400, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // QR scan square button
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push<String>(
                              MaterialPageRoute<String>(
                                builder: (_) => const QRScannerScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: primaryBlue, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. TÓM TẮT DỰ TRÙ VẮC-XIN PHIÊN TIÊM ──────────
            const SliverToBoxAdapter(
              child: SectionLabel('TÓM TẮT DỰ TRÙ VẮC-XIN PHIÊN TIÊM'),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    // Blue circle badge "4"
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${scheduleList.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: primaryBlue),
                              const SizedBox(width: 4),
                              Text(
                                _selectedVillage.isEmpty ? 'Tất cả địa bàn' : _selectedVillage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'DPT Mũi 3 (2) • Sởi Mũi 1 (2)',
                            style: TextStyle(fontSize: 11.5, color: gray600),
                          ),
                        ],
                      ),
                    ),
                    // Pill chip on right "Hộp nhỏ 2.5L"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryBlue),
                      ),
                      child: const Text(
                        'Hộp nhỏ 2.5L',
                        style: TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. XUẤT BÁO CÁO ─────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionLabel('XUẤT BÁO CÁO VÀ DANH SÁCH TIÊM CHỦNG'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ExportButton(
                        icon: Icons.table_chart_rounded,
                        label: 'Xuất CSV',
                        subtitle: 'Mở Excel',
                        color: const Color(0xFF059669),
                        onTap: () async {
                          final children = AppScope.of(context).children;
                          final reporterName = AppScope.of(context).currentUser?.fullName ?? 'Cán bộ Y tế';
                          final result = await ReportExportService.instance.exportChildrenToCsv(children);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result != null ? '✅ Đã xuất CSV thành công!' : '❌ Xuất thất bại!'),
                              backgroundColor: result != null ? primaryDark : accentRed,
                            ),
                          );
                          NotificationService.instance.sendSystemNotification(
                            title: '📄 Xuất báo cáo thành công',
                            body: 'Báo cáo tiêm chủng đã được xuất bởi $reporterName.',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExportButton(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'Xuất PDF',
                        subtitle: 'In báo cáo',
                        color: const Color(0xFFDC2626),
                        onTap: () async {
                          final store = AppScope.of(context);
                          final reporterName = store.currentUser?.fullName ?? 'Cán bộ Y tế';
                          final commune = store.currentUser?.assignedCommune ?? 'Tả Phìn';
                          await ReportExportService.instance.exportLatePdfReport(
                            children: store.children,
                            reporterName: reporterName,
                            commune: commune,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 5. DANH SÁCH CẦN TIÊM CHÚNG THỰC ĐỊA ─────────
            const SliverToBoxAdapter(
              child: SectionLabel('DANH SÁCH CẦN TIÊM CHÚNG THỰC ĐỊA'),
            ),

            // Chip Filter row
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả bản ($totalCount)', ''),
                    _buildFilterChip('Bản Nậm Lùng ($namLungCount)', 'Bản Nậm Lùng'),
                    _buildFilterChip('Bản Sapa ($sapaCount)', 'Bản Sapa'),
                    _buildFilterChip('Bản Cát Cát ($catCatCount)', 'Bản Cát Cát'),
                  ],
                ),
              ),
            ),

            // Children List Cards
            scheduleList.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Không có trẻ nào trong địa bàn này.', style: TextStyle(color: gray500, fontSize: 13)),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == scheduleList.length) return const SizedBox(height: 24);
                        final child = scheduleList[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildChildRow(context, child),
                        );
                      },
                      childCount: scheduleList.length + 1,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedVillage == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedVillage = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
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

  Widget _buildChildRow(BuildContext context, ChildProfile child) {
    Color pillBg;
    Color pillFg;
    String pillText;

    if (child.lateDays > 0) {
      pillBg = redLight;
      pillFg = accentRed;
      pillText = 'Trễ ${child.lateDays} ngày';
    } else if (child.status == ChildVaccinationStatus.dueSoon) {
      pillBg = yellowLight;
      pillFg = accentYellow;
      pillText = 'Hẹn ${formatDate(child.nextDue)}';
    } else {
      pillBg = primaryLight;
      pillFg = primaryDark;
      pillText = 'Đủ lịch';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 4)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChildDetailScreen(childId: child.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar circle with first letter
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: blueLight, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    child.fullName.characters.first,
                    style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 15),
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: gray900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.village} • ${child.nextVaccine} • Mẹ: ${child.motherName}',
                      style: const TextStyle(fontSize: 11.5, color: gray500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  pillText,
                  style: TextStyle(color: pillFg, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export Button Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: gray500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
