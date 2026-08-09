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
  String? _village;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: redLight, shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: accentRed, size: 28),
        ),
        title: const Text('Cảnh báo xóa hồ sơ trẻ',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: gray900)),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của trẻ "${child.fullName}"? Dữ liệu này không thể khôi phục.',
            style: const TextStyle(fontSize: 13, color: gray600, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: gray700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accentRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.w800)),
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

    // Get unique villages
    final villages = store.children.map((child) => child.village).toSet().toList()..sort();

    final filtered = store.children.where((child) {
      final q = _query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          child.fullName.toLowerCase().contains(q) ||
          child.qrCode.toLowerCase().contains(q) ||
          child.motherName.toLowerCase().contains(q);
      final matchesVillage = _village == null || child.village == _village;
      return matchesQuery && matchesVillage;
    }).toList();

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 48, bottom: 0),
            child: Column(
              children: [
                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      const Text(
                        'Phụ huynh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: gray900,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openAddChild,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: blueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded, color: primaryBlue, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: gray200),
              ],
            ),
          ),

          // ── Search + QR ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: gray100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gray200),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(Icons.search_rounded, color: gray400, size: 16),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _query = value);
                              store.searchChildren(value);
                            },
                            style: const TextStyle(fontSize: 13, color: gray900),
                            decoration: const InputDecoration(
                              hintText: 'Nhập họ tên cha mẹ, con, CCCD...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              hintStyle: TextStyle(color: gray400, fontSize: 12.5),
                              fillColor: Colors.transparent,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // QR scan
                GestureDetector(
                  onTap: () async {
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
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gray200, width: 1.2),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: primaryBlue, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Village chip filter ──────────────────────────────
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: 'Tất cả bản',
                      selected: _village == null,
                      onTap: () => setState(() => _village = null),
                    ),
                  ),
                  ...villages.map((v) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: v,
                          selected: _village == v,
                          onTap: () => setState(() => _village = v),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Container(height: 1, color: gray200),

          // ── Children List ────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'Không tìm thấy trẻ',
                    description: 'Hãy thử đổi từ khóa hoặc bấm nút + để thêm trẻ mới.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final child = filtered[index];
                      return _buildChildRow(context, child);
                    },
                  ),
          ),
        ],
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
      pillText = 'Sắp lịch';
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
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
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: blueLight, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    child.fullName.characters.first,
                    style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 14),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: gray900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.village} · Mẹ: ${child.motherName}',
                      style: const TextStyle(fontSize: 11.5, color: gray500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(6)),
                child: Text(pillText, style: TextStyle(color: pillFg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
              // Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: gray400, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') _openEditChild(child);
                  if (val == 'delete') _confirmDeleteChild(child);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: gray600),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa', style: TextStyle(color: gray700)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: accentRed),
                      SizedBox(width: 8),
                      Text('Xóa hồ sơ', style: TextStyle(color: accentRed)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
