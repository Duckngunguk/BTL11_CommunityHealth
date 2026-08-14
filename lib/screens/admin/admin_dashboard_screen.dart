import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/report_export_service.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final total =
        store.communeCoverage.fold<int>(0, (sum, item) => sum + item.total);
    final fully =
        store.communeCoverage.fold<int>(0, (sum, item) => sum + item.fully);
    final coverage = total > 0 ? (fully / total * 100.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        if (isWide) {
          // ── Widescreen Desktop Layout (Main column + Sidebar column) ──
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Left Area (65% width)
              Expanded(
                flex: 13,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildWelcomeBanner(store),
                    const SizedBox(height: 20),
                    _buildExportActions(context, store),
                    const SizedBox(height: 20),
                    _buildMetricsGrid(store, total, fully, coverage,
                        columnsCount: 4),
                    const SizedBox(height: 20),
                    _buildStatusBanner(context, store.lateCount),
                    const SizedBox(height: 20),
                    _CoverageOverviewCard(),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: gray200),
              // Right Sidebar Area (35% width)
              Expanded(
                flex: 7,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _RecentActivitiesCard(store: store),
                    const SizedBox(height: 20),
                    _OutbreaksAlertCard(store: store),
                    const SizedBox(height: 20),
                    _AlertCard(store: store),
                  ],
                ),
              ),
            ],
          );
        }

        // ── Mobile / Tablet Compact Layout (Single column scroll) ──
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWelcomeBanner(store),
            const SizedBox(height: 16),
            _buildExportActions(context, store),
            const SizedBox(height: 16),
            _buildMetricsGrid(store, total, fully, coverage, columnsCount: 2),
            const SizedBox(height: 16),
            _buildStatusBanner(context, store.lateCount),
            const SizedBox(height: 16),
            _CoverageOverviewCard(),
            const SizedBox(height: 16),
            _RecentActivitiesCard(store: store),
            const SizedBox(height: 16),
            _OutbreaksAlertCard(store: store),
            const SizedBox(height: 16),
            _AlertCard(store: store),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeBanner(AppStore store) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRUNG TÂM Y TẾ HUYỆN SA PA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: gray500,
                    letterSpacing: 0.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Xin chào, ${store.currentUser?.fullName ?? 'Quản trị viên'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: gray900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Theo dõi tỷ lệ bao phủ vaccine, giám sát ổ dịch và quản lý nhân sự địa phương.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: gray600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildPillBadge(
              'Đã xác thực', const Color(0xFF18794E), const Color(0xFFE5F5EC)),
          const SizedBox(width: 8),
          _buildPillBadge(
              'Cổng Huyện', const Color(0xFFB06000), const Color(0xFFFEF7E0)),
        ],
      ),
    );
  }

  Widget _buildExportActions(BuildContext context, AppStore store) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final children = store.children;
              final result = await ReportExportService.instance
                  .exportChildrenToCsv(children);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result != null
                      ? 'Đã tải file "$result". Kiểm tra thư mục Downloads.'
                      : 'Không thể xuất file CSV.'),
                  backgroundColor: result != null
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              );
            },
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: const Text('Xuất Excel/CSV',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              side: const BorderSide(color: Color(0xFF059669)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final children = store.children;
              final result =
                  await ReportExportService.instance.exportLatePdfReport(
                children: children,
                reporterName: store.currentUser?.fullName ?? 'Admin',
                commune: 'Toàn huyện',
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result != null
                      ? 'Đã mở bản xem trước "$result". Chọn Save để lưu file.'
                      : 'Đã hủy xuất PDF.'),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Xuất PDF Báo cáo',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(
      AppStore store, int total, int fully, double coverage,
      {required int columnsCount}) {
    return GridView.count(
      crossAxisCount: columnsCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: columnsCount == 4 ? 1.05 : 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _DashboardStatCard(
          label: 'Trẻ 0–5 tuổi',
          value: '$total',
          icon: Icons.groups_2_outlined,
          iconColor: primaryBlue,
          iconBgColor: blueLight,
          caption: '6 xã đang theo dõi',
        ),
        _DashboardStatCard(
          label: 'Đã tiêm đầy đủ',
          value: '$fully',
          icon: Icons.verified_outlined,
          iconColor: primaryDark,
          iconBgColor: primaryLight,
          caption: '${coverage.toStringAsFixed(1)}% toàn huyện',
        ),
        _DashboardStatCard(
          label: 'Trẻ trễ lịch',
          value: '${store.lateCount}',
          icon: Icons.warning_amber_rounded,
          iconColor: accentRed,
          iconBgColor: redLight,
          caption: 'Cần ưu tiên liên hệ',
        ),
        _DashboardStatCard(
          label: 'Kế hoạch tiêm',
          value: '${store.vaccinePlans.length}',
          icon: Icons.event_available_outlined,
          iconColor: accentYellow,
          iconBgColor: yellowLight,
          caption: 'Kế hoạch đã phát lệnh',
        ),
      ],
    );
  }

  Widget _buildPillBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, int lateCount) {
    final hasAlert = lateCount > 0;
    final Color bgColor =
        hasAlert ? const Color(0xFFFFE9E7) : const Color(0xFFE6F4EA);
    final Color borderColor =
        hasAlert ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0);
    final Color textColor =
        hasAlert ? const Color(0xFF991B1B) : const Color(0xFF065F46);
    final IconData icon = hasAlert
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasAlert
                  ? 'Hệ thống phát hiện $lateCount trẻ đang trễ lịch tiêm chủng. Vui lòng đôn đốc Cán bộ Y tế xã liên hệ gia đình tiêm bổ sung.'
                  : 'Hệ thống ghi nhận không có trẻ trễ lịch tiêm chủng cần xử lý khẩn cấp.',
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: gray500,
                    letterSpacing: 0.03,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: gray900,
                    height: 1.1,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Tỷ lệ phủ theo xã',
              subtitle: 'Xanh ≥ 80%, vàng 60–79%, đỏ < 60%.'),
          const SizedBox(height: 20),
          ...store.communeCoverage.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    SizedBox(
                        width: 100,
                        child: Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: gray800))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: item.coverage / 100,
                          minHeight: 11,
                          backgroundColor: const Color(0xFFE8ECEA),
                          color: item.coverage >= 80
                              ? const Color(0xFF27AE60)
                              : item.coverage >= 60
                                  ? const Color(0xFFF2C94C)
                                  : const Color(0xFFEB5757),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 52,
                        child: Text('${item.coverage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: gray900))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  const _RecentActivitiesCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final recentLogs = store.auditLogs.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.history_rounded,
                    color: Colors.purple.shade700, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'HOẠT ĐỘNG GẦN ĐÂY',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentLogs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Chưa có hoạt động nào.',
                    style: TextStyle(color: gray500, fontSize: 13)),
              ),
            )
          else
            ...recentLogs.map((log) {
              final formattedTime =
                  '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.action,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.details,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bởi: ${log.performedBy} (${log.userRole})',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _OutbreaksAlertCard extends StatelessWidget {
  const _OutbreaksAlertCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final activeOutbreaks = store.diseaseReports
        .where((r) => r.status != 'Đã khỏi')
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.crisis_alert_rounded,
                    color: Colors.red.shade700, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'CẢNH BÁO DỊCH TỄ',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeOutbreaks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Không ghi nhận ổ dịch hoạt động.',
                    style: TextStyle(color: gray500, fontSize: 13)),
              ),
            )
          else
            ...activeOutbreaks.map((report) {
              final color = report.severity == DiseaseSeverity.severe
                  ? Colors.red
                  : (report.severity == DiseaseSeverity.moderate
                      ? Colors.orange
                      : Colors.blue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            report.diseaseType,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: color),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.status,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Địa điểm: ${report.village}, Xã ${report.commune}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Bệnh nhân: ${report.patientName}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final late = store.children.where((child) => child.lateDays > 0).toList();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'CẢNH BÁO TRỄ LỊCH',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (late.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có cảnh báo trễ lịch',
                  style: TextStyle(color: gray500, fontSize: 13),
                ),
              ),
            )
          else
            ...late.take(3).map((child) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFE9E7),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFB42318), size: 18)),
                  title: Text(child.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: gray900)),
                  subtitle: Text('${child.commune} • ${child.nextVaccine}',
                      style: const TextStyle(fontSize: 11.5, color: gray500)),
                  trailing: Text('${child.lateDays} ngày',
                      style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                )),
        ],
      ),
    );
  }
}
