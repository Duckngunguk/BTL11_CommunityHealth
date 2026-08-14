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
    if (widget.initialStatusFilter != null &&
        widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      _selectedStatusFilter = widget.initialStatusFilter!;
    }
  }

  Future<void> _showCreateHealthStaffDialog(AppStore store) async {
    final created = await showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateHealthStaffDialog(store: store),
    );
    if (!mounted || created == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã tạo tài khoản cán bộ "${created.fullName}". Cán bộ có thể đăng nhập ngay.',
        ),
        backgroundColor: const Color(0xFF18794E),
      ),
    );
  }

  void _showApprovalDialog(
      BuildContext context, UserModel user, AppStore store) {
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
              child: const Icon(Icons.person_add_rounded,
                  color: Color(0xFFB42318)),
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
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await store.rejectUser(user.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã từ chối đơn đăng ký tài khoản của "${user.fullName}"'),
                  backgroundColor: const Color(0xFF666666),
                ),
              );
            },
            icon: const Icon(Icons.close_rounded, color: Color(0xFFB42318)),
            label: const Text('Từ chối đơn',
                style: TextStyle(color: Color(0xFFB42318))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB42318)),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await store.approveUser(user.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã phê duyệt tài khoản "${user.fullName}" thành công!'),
                  backgroundColor: const Color(0xFF18794E),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Phê duyệt ngay'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF18794E)),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
    final pendingUsers = store.users
        .where((u) =>
            u.role == UserRole.healthWorker &&
            u.status == UserAccountStatus.pendingApproval)
        .toList();
    final users = store.users.where((u) {
      if (_selectedStatusFilter == 'Chờ duyệt' &&
          u.status != UserAccountStatus.pendingApproval) {
        return false;
      }
      if (_selectedStatusFilter == 'Hoạt động' &&
          u.status != UserAccountStatus.active) {
        return false;
      }
      if (_selectedStatusFilter == 'Đã từ chối' &&
          u.status != UserAccountStatus.rejected) {
        return false;
      }
      if (_selectedStatusFilter == 'Tài khoản bị khóa' &&
          u.status != UserAccountStatus.locked) {
        return false;
      }

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Quản lý Người dùng & Phân quyền',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            if (store.pendingUserApprovals > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
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
                          'Admin tạo tài khoản Cán bộ Y tế, phân công xã và quản lý trạng thái truy cập.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showCreateHealthStaffDialog(store),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Thêm cán bộ y tế'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await store.syncFromStorage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '🎉 Đã làm mới và đồng bộ danh sách tài khoản mới nhất!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Đồng bộ dữ liệu'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
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
                        const Icon(Icons.notification_important_rounded,
                            color: Color(0xFFB42318), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Danh sách Đơn đăng ký Cán bộ Y tế cần Admin Phê duyệt (${pendingUsers.length})',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB42318)),
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
                                  style: const TextStyle(
                                      color: Color(0xFFB42318),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pUser.fullName} (@${pUser.username})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Email: ${pUser.email} • SĐT: ${pUser.phone} • Xã: ${pUser.assignedCommune ?? "Chưa xếp"}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  await store.rejectUser(pUser.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Đã từ chối tài khoản "${pUser.fullName}"')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB42318),
                                  side: const BorderSide(
                                      color: Color(0xFFFECDCA)),
                                ),
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () =>
                                    _showApprovalDialog(context, pUser, store),
                                icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16),
                                label: const Text('Xem & Duyệt'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF18794E)),
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
                        hintText:
                            'Tìm theo Tên, Username, Email, Số điện thoại...',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Trạng thái: ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items: [
                      'Tất cả',
                      'Chờ duyệt',
                      'Hoạt động',
                      'Đã từ chối',
                      'Tài khoản bị khóa'
                    ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatusFilter = val);
                      }
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
                    child:
                        Center(child: Text('Không tìm thấy người dùng nào.')),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                            label: Text('Người dùng',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Tài khoản / Email',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Vai trò',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Xã phụ trách',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Trạng thái',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Thao tác',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: users.map((user) {
                        final isPending =
                            user.status == UserAccountStatus.pendingApproval;
                        final isLocked =
                            user.status == UserAccountStatus.locked;

                        final (statusLabel, statusColor, statusBg) =
                            switch (user.status) {
                          UserAccountStatus.pendingApproval => (
                              'Chờ Admin duyệt',
                              const Color(0xFFB42318),
                              const Color(0xFFFFE9E7)
                            ),
                          UserAccountStatus.active => (
                              'Đang hoạt động',
                              const Color(0xFF18794E),
                              const Color(0xFFE5F5EC)
                            ),
                          UserAccountStatus.rejected => (
                              'Đã từ chối',
                              const Color(0xFFB42318),
                              const Color(0xFFFFE9E7)
                            ),
                          UserAccountStatus.locked => (
                              'Đã bị khóa',
                              const Color(0xFF666666),
                              const Color(0xFFEEEEEE)
                            ),
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
                                    backgroundColor: isPending
                                        ? const Color(0xFFFFE9E7)
                                        : const Color(0xFFE5F5EC),
                                    child: Text(
                                      user.fullName.characters.first,
                                      style: TextStyle(
                                        color: isPending
                                            ? const Color(0xFFB42318)
                                            : primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text(user.phone,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54)),
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
                                  Text(user.username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(user.email,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            DataCell(
                              Chip(
                                label: Text(roleLabel,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                                backgroundColor: const Color(0xFFF0F4F8),
                                side: BorderSide.none,
                              ),
                            ),
                            DataCell(Text(user.assignedCommune ?? '—')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  if (isPending) ...[
                                    FilledButton.icon(
                                      onPressed: () => _showApprovalDialog(
                                          context, user, store),
                                      icon: const Icon(Icons.check_rounded,
                                          size: 16),
                                      label: const Text('Phê duyệt'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF18794E),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: () async {
                                        await store.rejectUser(user.id);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Đã từ chối tài khoản "${user.fullName}"')),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFB42318),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                  ] else if (user.role != UserRole.admin)
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        store.toggleUserStatus(user.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Đã ${isLocked ? "mở khóa" : "khóa"} tài khoản "${user.username}"')),
                                        );
                                      },
                                      icon: Icon(
                                          isLocked
                                              ? Icons.lock_open_rounded
                                              : Icons.lock_outline_rounded,
                                          size: 16),
                                      label:
                                          Text(isLocked ? 'Mở khóa' : 'Khóa'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
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

class _CreateHealthStaffDialog extends StatefulWidget {
  const _CreateHealthStaffDialog({required this.store});

  final AppStore store;

  @override
  State<_CreateHealthStaffDialog> createState() =>
      _CreateHealthStaffDialogState();
}

class _CreateHealthStaffDialogState extends State<_CreateHealthStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _staffCodeController = TextEditingController();
  final _facilityController =
      TextEditingController(text: 'Trạm Y tế xã Tả Phìn');
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _communes = [
    'Tả Phìn',
    'Hầu Thào',
    'San Sả Hồ',
    'Tả Van',
    'Lao Chải',
    'Bản Hồ',
  ];

  DateTime? _dateOfBirth;
  String _gender = 'Nữ';
  String _commune = _communes.first;
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _staffCodeController.dispose();
    _facilityController.dispose();
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Thông tin bắt buộc' : null;

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (selected == null) return;
    setState(() {
      _dateOfBirth = selected;
      _dateController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final response = await widget.store.createHealthStaffByAdmin(
      username: _usernameController.text,
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      assignedCommune: _commune,
      staffCode: _staffCodeController.text,
      healthFacility: _facilityController.text,
      professionalTitle: _titleController.text,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
    );
    if (!mounted) return;
    if (response.success && response.data != null) {
      Navigator.of(context).pop(response.data);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = response.error ?? 'Không thể tạo tài khoản cán bộ.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: primaryGreen),
          SizedBox(width: 10),
          Text('Thêm cán bộ y tế'),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Giới tính',
                          prefixIcon: Icon(Icons.wc_rounded),
                        ),
                        items: const ['Nữ', 'Nam', 'Khác']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _gender = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        validator: (value) {
                          if (_required(value) != null) return _required(value);
                          return value!.contains('@')
                              ? null
                              : 'Email không hợp lệ';
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
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _staffCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã cán bộ *',
                          prefixIcon: Icon(Icons.numbers_rounded),
                        ),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _commune,
                        decoration: const InputDecoration(
                          labelText: 'Xã phụ trách *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: _communes
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _commune = value;
                            _facilityController.text = 'Trạm Y tế xã $value';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _facilityController,
                  decoration: const InputDecoration(
                    labelText: 'Cơ sở y tế *',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ/chuyên môn *',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    hintText: 'Ví dụ: Y sĩ đa khoa',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => (value ?? '').trim().length < 4
                            ? 'Tối thiểu 4 ký tự'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                          ),
                        ),
                        validator: (value) => (value ?? '').length < 6
                            ? 'Tối thiểu 6 ký tự'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Vai trò: Cán bộ Y tế • Trạng thái: Hoạt động',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Tạo tài khoản'),
          style: FilledButton.styleFrom(backgroundColor: primaryGreen),
        ),
      ],
    );
  }
}
