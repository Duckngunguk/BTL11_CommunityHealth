import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key, this.initialStatusFilter});

  final String? initialStatusFilter;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late String _selectedStatusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = widget.initialStatusFilter ?? 'Tất cả';
  }

  @override
  void didUpdateWidget(covariant UserManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != null && widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      _selectedStatusFilter = widget.initialStatusFilter!;
    }
  }

  void _showApprovalDialog(BuildContext context, UserModel user, AppStore store) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_rounded, color: Color(0xFFB42318)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xét duyệt Đơn Đăng ký',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _infoRow('Họ và tên:', user.fullName, isBold: true),
                    const Divider(height: 12),
                    _infoRow('Tên đăng nhập:', '@${user.username}'),
                    const Divider(height: 12),
                    _infoRow('Email:', user.email),
                    const Divider(height: 12),
                    _infoRow('Số điện thoại:', user.phone),
                    const Divider(height: 12),
                    _infoRow(
                      'Vai trò đăng ký:',
                      user.role == UserRole.healthWorker
                          ? 'Cán bộ Y tế'
                          : user.role == UserRole.admin
                              ? 'Quản trị viên'
                              : 'Phụ huynh',
                    ),
                    if (user.assignedCommune != null) ...[
                      const Divider(height: 12),
                      _infoRow('Xã phụ trách:', 'Xã ${user.assignedCommune}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Lưu ý: Sau khi được phê duyệt, người dùng có thể dùng tài khoản này để đăng nhập ngay vào hệ thống.',
                style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              store.rejectUser(user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã từ chối đơn đăng ký tài khoản của "${user.fullName}"'),
                  backgroundColor: const Color(0xFF666666),
                ),
              );
            },
            icon: const Icon(Icons.close_rounded, color: Color(0xFFB42318)),
            label: const Text('Từ chối đơn', style: TextStyle(color: Color(0xFFB42318))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB42318)),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              store.approveUser(user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã phê duyệt tài khoản "${user.fullName}" thành công!'),
                  backgroundColor: const Color(0xFF18794E),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Phê duyệt ngay'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF18794E)),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pendingUsers = store.users.where((u) => u.status == UserAccountStatus.pendingApproval).toList();
    final users = store.users.where((u) {
      if (_selectedStatusFilter == 'Chờ duyệt' && u.status != UserAccountStatus.pendingApproval) return false;
      if (_selectedStatusFilter == 'Hoạt động' && u.status != UserAccountStatus.active) return false;
      if (_selectedStatusFilter == 'Tài khoản bị khóa' && u.status != UserAccountStatus.locked) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(query) ||
            u.username.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.phone.contains(query);
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.manage_accounts_rounded, color: primaryGreen, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Quản lý Người dùng & Phân quyền',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        if (store.pendingUserApprovals > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE9E7),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${store.pendingUserApprovals} tài khoản chờ duyệt',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB42318),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Phê duyệt Cán bộ Y tế xã mới đăng ký, quản lý phân quyền và khóa/mở tài khoản.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Khối Yêu cầu chờ duyệt nổi bật
          if (pendingUsers.isNotEmpty) ...[
            Card(
              color: const Color(0xFFFFF8F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFECDCA), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notification_important_rounded, color: Color(0xFFB42318), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Danh sách Đơn đăng ký Cán bộ Y tế cần Admin Phê duyệt (${pendingUsers.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFB42318)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: pendingUsers.map((pUser) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFFFE9E7),
                                child: Text(
                                  pUser.fullName.characters.first,
                                  style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pUser.fullName} (@${pUser.username})',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Email: ${pUser.email} • SĐT: ${pUser.phone} • Xã: ${pUser.assignedCommune ?? "Chưa xếp"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  store.rejectUser(pUser.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã từ chối tài khoản "${pUser.fullName}"')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB42318),
                                  side: const BorderSide(color: Color(0xFFFECDCA)),
                                ),
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () => _showApprovalDialog(context, pUser, store),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text('Xem & Duyệt'),
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF18794E)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Bộ lọc & Tìm kiếm
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo Tên, Username, Email, Số điện thoại...',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items: ['Tất cả', 'Chờ duyệt', 'Hoạt động', 'Tài khoản bị khóa']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bảng danh sách người dùng
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Danh sách Người dùng Hệ thống',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Không tìm thấy người dùng nào.')),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Tài khoản / Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Xã phụ trách', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: users.map((user) {
                        final isPending = user.status == UserAccountStatus.pendingApproval;
                        final isLocked = user.status == UserAccountStatus.locked;

                        final (statusLabel, statusColor, statusBg) = switch (user.status) {
                          UserAccountStatus.pendingApproval => ('Chờ Admin duyệt', const Color(0xFFB42318), const Color(0xFFFFE9E7)),
                          UserAccountStatus.active => ('Đang hoạt động', const Color(0xFF18794E), const Color(0xFFE5F5EC)),
                          UserAccountStatus.locked => ('Đã bị khóa', const Color(0xFF666666), const Color(0xFFEEEEEE)),
                        };

                        final roleLabel = switch (user.role) {
                          UserRole.admin => 'Quản trị viên',
                          UserRole.healthWorker => 'Cán bộ Y tế',
                          UserRole.parent => 'Phụ huynh',
                        };

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPending ? const Color(0xFFFFE9E7) : const Color(0xFFE5F5EC),
                                    child: Text(
                                      user.fullName.characters.first,
                                      style: TextStyle(
                                        color: isPending ? const Color(0xFFB42318) : primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(user.phone, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            DataCell(
                              Chip(
                                label: Text(roleLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                backgroundColor: const Color(0xFFF0F4F8),
                                side: BorderSide.none,
                              ),
                            ),
                            DataCell(Text(user.assignedCommune ?? '—')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  if (isPending) ...[
                                    FilledButton.icon(
                                      onPressed: () => _showApprovalDialog(context, user, store),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Phê duyệt'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF18794E),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: () {
                                        store.rejectUser(user.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Đã từ chối tài khoản "${user.fullName}"')),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFB42318),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                  ] else if (user.role != UserRole.admin)
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        store.toggleUserStatus(user.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Đã ${isLocked ? "mở khóa" : "khóa"} tài khoản "${user.username}"')),
                                        );
                                      },
                                      icon: Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 16),
                                      label: Text(isLocked ? 'Mở khóa' : 'Khóa'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
