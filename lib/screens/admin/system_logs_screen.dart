import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    final logs = store.auditLogs.where((log) {
      if (_selectedRole != 'Tất cả' && log.userRole != _selectedRole) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return log.action.toLowerCase().contains(q) ||
            log.performedBy.toLowerCase().contains(q) ||
            log.details.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF6A1B9A), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhật ký Hoạt động Hệ thống',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ghi nhận toàn bộ thao tác: Đăng nhập, Khai báo dịch bệnh, Ghi nhận tiêm, Phê duyệt tài khoản...',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI thống kê
          Row(
            children: [
              Expanded(
                child: _LogStatCard(
                  label: 'Tổng hoạt động',
                  value: '${store.auditLogs.length}',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF6A1B9A),
                  bg: const Color(0xFFEDE7F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogStatCard(
                  label: 'Hôm nay',
                  value: '${store.auditLogs.where((l) => l.timestamp.day == DateTime.now().day).length}',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF1565C0),
                  bg: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogStatCard(
                  label: 'Cán bộ Y tế',
                  value: '${store.auditLogs.where((l) => l.userRole == "Cán bộ Y tế").length}',
                  icon: Icons.medical_services_outlined,
                  color: primaryGreen,
                  bg: const Color(0xFFE5F5EC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogStatCard(
                  label: 'Quản trị viên',
                  value: '${store.auditLogs.where((l) => l.userRole == "Quản trị viên").length}',
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFFB42318),
                  bg: const Color(0xFFFFE9E7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bộ lọc
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo hành động, người thực hiện...',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Vai trò: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: ['Tất cả', 'Cán bộ Y tế', 'Phụ huynh', 'Quản trị viên']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách log
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nhật ký hoạt động (${logs.length} bản ghi)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                if (logs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Không có nhật ký nào phù hợp với bộ lọc.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _LogTile(log: logs[index]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogStatCard extends StatelessWidget {
  const _LogStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final SystemAuditLog log;

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, iconBg) = switch (log.action) {
      'Đăng nhập hệ thống' => (Icons.login_rounded, const Color(0xFF1565C0), const Color(0xFFDBEAFE)),
      'Ghi nhận tiêm chủng' => (Icons.vaccines_rounded, primaryGreen, const Color(0xFFE5F5EC)),
      'Khai báo dịch bệnh' => (Icons.coronavirus_rounded, const Color(0xFFB42318), const Color(0xFFFFE9E7)),
      'Phê duyệt tài khoản' => (Icons.verified_user_rounded, const Color(0xFF6A1B9A), const Color(0xFFEDE7F6)),
      'Cập nhật khoanh vùng dịch' => (Icons.crisis_alert_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      'Đồng bộ dữ liệu' => (Icons.sync_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5)),
      _ => (Icons.history_rounded, Colors.black54, const Color(0xFFF0F4F8)),
    };

    final now = DateTime.now();
    final diff = now.difference(log.timestamp);
    final timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes} phút trước'
        : diff.inHours < 24
            ? '${diff.inHours} giờ trước'
            : '${diff.inDays} ngày trước';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(log.userRole, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.details,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(log.performedBy, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeAgo, style: const TextStyle(fontSize: 11, color: Colors.black38)),
              const SizedBox(height: 4),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
