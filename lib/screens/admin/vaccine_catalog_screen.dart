import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../widgets/common_widgets.dart';

class VaccineCatalogScreen extends StatelessWidget {
  const VaccineCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader(
          title: 'Danh mục lịch vaccine',
          subtitle: 'Dữ liệu chuẩn dùng để tính mũi đến hạn cho từng trẻ.',
          trailing: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('Thêm lịch')),
        ),
        const SizedBox(height: 18),
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
              rows: demoSchedules.map((item) => DataRow(cells: [
                    DataCell(Text(item.id)),
                    DataCell(Text(item.vaccineName, style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text('${item.doseNumber}')),
                    DataCell(Text('${item.ageMonths} tháng')),
                    DataCell(Text('± ${item.toleranceDays} ngày')),
                    DataCell(SizedBox(width: 310, child: Text(item.description))),
                  ])).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
