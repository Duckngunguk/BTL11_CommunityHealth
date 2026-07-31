import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../widgets/common_widgets.dart';

class VaccineCatalogScreen extends StatefulWidget {
  const VaccineCatalogScreen({super.key});

  @override
  State<VaccineCatalogScreen> createState() => _VaccineCatalogScreenState();
}

class _VaccineCatalogScreenState extends State<VaccineCatalogScreen> {
  int _selectedCatalog = 0; // 0: Vaccine, 1: Thuốc uống

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader(
          title: 'Danh mục Y tế Chuẩn',
          subtitle: 'Dữ liệu chuẩn tiêm chủng và bổ sung thuốc đường uống cho trẻ em.',
          trailing: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_selectedCatalog == 0 ? 'Thêm lịch vaccine mới (Mô phỏng)' : 'Thêm danh mục thuốc uống mới (Mô phỏng)'),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(_selectedCatalog == 0 ? 'Thêm lịch vaccine' : 'Thêm danh mục thuốc'),
          ),
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment<int>(
              value: 0,
              icon: Icon(Icons.vaccines_rounded),
              label: Text('Danh mục Vaccine tiêm'),
            ),
            ButtonSegment<int>(
              value: 1,
              icon: Icon(Icons.medication_rounded),
              label: Text('Danh mục Thuốc uống & Bổ sung'),
            ),
          ],
          selected: {_selectedCatalog},
          onSelectionChanged: (set) => setState(() => _selectedCatalog = set.first),
        ),
        const SizedBox(height: 18),
        if (_selectedCatalog == 0)
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mã')),
                  DataColumn(label: Text('Vaccine')),
                  DataColumn(label: Text('Mũi')),
                  DataColumn(label: Text('Tuổi tiêm')),
                  DataColumn(label: Text('Dung sai')),
                  DataColumn(label: Text('Mô tả')),
                ],
                rows: demoSchedules
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item.id)),
                          DataCell(Text(item.vaccineName, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text('${item.doseNumber}')),
                          DataCell(Text('${item.ageMonths} tháng')),
                          DataCell(Text('± ${item.toleranceDays} ngày')),
                          DataCell(SizedBox(width: 310, child: Text(item.description))),
                        ]))
                    .toList(),
              ),
            ),
          )
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mã')),
                  DataColumn(label: Text('Tên thuốc / Bổ sung')),
                  DataColumn(label: Text('Độ tuổi khuyến nghị')),
                  DataColumn(label: Text('Liều dùng chuẩn')),
                  DataColumn(label: Text('Mô tả')),
                ],
                rows: demoMedicationSchedules
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item.id)),
                          DataCell(Text(item.medicationName, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text(item.recommendedAge)),
                          DataCell(Text(item.defaultDosage)),
                          DataCell(SizedBox(width: 310, child: Text(item.description))),
                        ]))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}
