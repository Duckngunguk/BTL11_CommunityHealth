import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_detail_screen.dart';
import 'child_form_dialog.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ChildVaccinationStatus? _status;
  String? _commune;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddChild() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChildFormScreen()),
    );
  }

  void _openEditChild(ChildProfile child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChildFormScreen(childToEdit: child)),
    );
  }

  Future<void> _confirmDeleteChild(ChildProfile child) async {
    final store = AppScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 36),
        title: const Text('Xác nhận xóa trẻ'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của trẻ "${child.fullName}"? Dữ liệu này không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa hồ sơ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      store.deleteChild(child.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa trẻ "${child.fullName}".')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final communes = store.children.map((child) => child.commune).toSet().toList()..sort();
    final filtered = store.children.where((child) {
      final q = _query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          child.fullName.toLowerCase().contains(q) ||
          child.qrCode.toLowerCase().contains(q) ||
          child.motherName.toLowerCase().contains(q);
      final matchesStatus = _status == null || child.status == _status;
      final matchesCommune = _commune == null || child.commune == _commune;
      return matchesQuery && matchesStatus && matchesCommune;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddChild,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm trẻ'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Tên trẻ, tên mẹ hoặc mã QR...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    IconButton(
                      tooltip: 'Quét QR demo',
                      onPressed: () {
                        _searchController.text = 'CH-QR-0001';
                        setState(() => _query = 'CH-QR-0001');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã mô phỏng quét QR: CH-QR-0001')),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ],
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownMenu<String?>(
                        width: 170,
                        label: const Text('Xã'),
                        initialSelection: _commune,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry(value: null, label: 'Tất cả xã'),
                          ...communes.map((commune) => DropdownMenuEntry(value: commune, label: commune)),
                        ],
                        onSelected: (value) => setState(() => _commune = value),
                      ),
                      const SizedBox(width: 10),
                      DropdownMenu<ChildVaccinationStatus?>(
                        width: 190,
                        label: const Text('Trạng thái'),
                        initialSelection: _status,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: null, label: 'Tất cả trạng thái'),
                          DropdownMenuEntry(value: ChildVaccinationStatus.complete, label: 'Đã tiêm đủ'),
                          DropdownMenuEntry(value: ChildVaccinationStatus.dueSoon, label: 'Sắp đến lịch'),
                          DropdownMenuEntry(value: ChildVaccinationStatus.late, label: 'Trễ lịch'),
                        ],
                        onSelected: (value) => setState(() => _status = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'Không tìm thấy trẻ',
                    description: 'Hãy thử đổi từ khóa hoặc bấm nút "+ Thêm trẻ" để tạo hồ sơ mới.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final child = filtered[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => ChildDetailScreen(childId: child.id)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: softGreen,
                                  child: Text(
                                    child.fullName.characters.first,
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: primaryGreen),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              child.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                            ),
                                          ),
                                          StatusPill(status: child.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${child.village}, ${child.commune}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tiếp theo: ${child.nextVaccine}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _openEditChild(child);
                                    } else if (val == 'delete') {
                                      _confirmDeleteChild(child);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('Chỉnh sửa'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Color(0xFFB42318), size: 20),
                                          SizedBox(width: 8),
                                          Text('Xóa trẻ', style: TextStyle(color: Color(0xFFB42318))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
