import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class CoverageScreen extends StatelessWidget {
  const CoverageScreen({super.key});

  Color _statusColor(double value) {
    if (value >= 80) return const Color(0xFF27AE60);
    if (value >= 60) return const Color(0xFFF2C94C);
    return const Color(0xFFEB5757);
  }

  void _showDetail(BuildContext context, CommuneCoverage item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết xã ${item.name}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VaccineProgress(label: 'BCG - Mũi 1', value: item.bcg),
              _VaccineProgress(label: 'DPT - Mũi 1', value: item.dpt1),
              _VaccineProgress(label: 'DPT - Mũi 2', value: item.dpt2),
              _VaccineProgress(label: 'DPT - Mũi 3', value: item.dpt3),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(title: 'Tỷ lệ trẻ được tiêm đầy đủ', subtitle: 'Nhấn vào một xã để xem chi tiết từng vaccine.'),
        const SizedBox(height: 18),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Xã')),
                DataColumn(label: Text('Tổng trẻ'), numeric: true),
                DataColumn(label: Text('Đã tiêm đủ'), numeric: true),
                DataColumn(label: Text('Còn thiếu'), numeric: true),
                DataColumn(label: Text('Tỷ lệ')),
                DataColumn(label: Text('Mức ưu tiên')),
              ],
              rows: demoCoverage.map((item) {
                final color = _statusColor(item.coverage);
                final priority = item.coverage < 60 ? 'Rất cao' : item.coverage < 80 ? 'Cần theo dõi' : 'Ổn định';
                return DataRow(
                  onSelectChanged: (_) => _showDetail(context, item),
                  cells: [
                    DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text('${item.total}')),
                    DataCell(Text('${item.fully}')),
                    DataCell(Text('${item.missing}')),
                    DataCell(SizedBox(
                      width: 180,
                      child: Row(children: [
                        Expanded(child: LinearProgressIndicator(value: item.coverage / 100, minHeight: 10, borderRadius: BorderRadius.circular(99), color: color)),
                        const SizedBox(width: 10),
                        Text('${item.coverage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                      child: Text(priority, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _VaccineProgress extends StatelessWidget {
  const _VaccineProgress({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text('$value%')]),
          const SizedBox(height: 7),
          LinearProgressIndicator(value: value / 100, minHeight: 10, borderRadius: BorderRadius.circular(99)),
        ],
      ),
    );
  }
}
