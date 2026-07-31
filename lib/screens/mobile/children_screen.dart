import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'child_detail_screen.dart';

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

    return Column(
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mô phỏng quét QR: CH-QR-0001')));
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
              ? const EmptyState(title: 'Không tìm thấy trẻ', description: 'Hãy thử đổi từ khóa hoặc bỏ bớt điều kiện lọc.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                                child: Text(child.fullName.characters.first, style: const TextStyle(fontWeight: FontWeight.w800, color: primaryGreen)),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                                        StatusPill(status: child.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('${child.village}, ${child.commune}', style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    Text('Tiếp theo: ${child.nextVaccine}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
