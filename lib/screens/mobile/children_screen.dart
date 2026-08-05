import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_detail_screen.dart';
import 'child_form_dialog.dart';
import 'qr_scanner_screen.dart';

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
  String? _village;
  String? _ageGroup;

  bool _initializedCommune = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedCommune) {
      final user = AppScope.of(context).currentUser;
      if (user?.assignedCommune != null) {
        _commune = user!.assignedCommune;
      }
      _initializedCommune = true;
    }
  }

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
    final villages = store.children
        .where((child) => _commune == null || child.commune == _commune)
        .map((child) => child.village)
        .toSet()
        .toList()
      ..sort();
    final filtered = store.children.where((child) {
      final q = _query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          child.fullName.toLowerCase().contains(q) ||
          child.qrCode.toLowerCase().contains(q) ||
          child.motherName.toLowerCase().contains(q);
      final matchesStatus = _status == null || child.status == _status;
      final matchesCommune = _commune == null || child.commune == _commune;
      final matchesVillage = _village == null || child.village == _village;
      
      bool matchesAge = true;
      if (_ageGroup != null) {
        final ageMonths = (DateTime.now().year - child.dateOfBirth.year) * 12 + DateTime.now().month - child.dateOfBirth.month;
        if (_ageGroup == 'under_1') {
          matchesAge = ageMonths < 12;
        } else if (_ageGroup == '1_to_3') {
          matchesAge = ageMonths >= 12 && ageMonths <= 36;
        } else if (_ageGroup == 'over_3') {
          matchesAge = ageMonths > 36;
        }
      }
      return matchesQuery && matchesStatus && matchesCommune && matchesVillage && matchesAge;
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
                      tooltip: 'Quét mã QR thẻ y tế',
                      onPressed: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute<String>(
                            builder: (_) => const QRScannerScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                        if (result != null && mounted) {
                          _searchController.text = result;
                          setState(() => _query = result);
                          store.searchChildren(result);
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _query = value);
                    store.searchChildren(value);
                  },
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
                        onSelected: (value) => setState(() {
                          _commune = value;
                          _village = null;
                        }),
                      ),
                      const SizedBox(width: 10),
                      DropdownMenu<String?>(
                        width: 185,
                        label: const Text('Thôn/bản'),
                        initialSelection: _village,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry(value: null, label: 'Tất cả thôn/bản'),
                          ...villages.map((v) => DropdownMenuEntry(value: v, label: v)),
                        ],
                        onSelected: (value) => setState(() => _village = value),
                      ),
                      const SizedBox(width: 10),
                      DropdownMenu<String?>(
                        width: 160,
                        label: const Text('Độ tuổi'),
                        initialSelection: _ageGroup,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: null, label: 'Tất cả độ tuổi'),
                          DropdownMenuEntry(value: 'under_1', label: 'Dưới 1 tuổi'),
                          DropdownMenuEntry(value: '1_to_3', label: '1 - 3 tuổi'),
                          DropdownMenuEntry(value: 'over_3', label: 'Trên 3 tuổi'),
                        ],
                        onSelected: (value) => setState(() => _ageGroup = value),
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
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Tiếp theo: ${child.nextVaccine}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          if (child.status == ChildVaccinationStatus.late && child.lateDays > 0) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '(Trễ ${child.lateDays} ngày)',
                                              style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w800, fontSize: 13),
                                            ),
                                          ],
                                        ],
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
