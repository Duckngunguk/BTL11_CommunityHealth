import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  CommuneCoverage _commune = demoCoverage.first;
  DateTime _date = DateTime(2026, 8, 5);
  bool _calculated = false;

  Map<String, int> get estimatedDoses {
    final base = _commune.missing;
    return {
      'BCG': (base * 0.25).ceil() + 2,
      'DPT': (base * 0.70).ceil() + 4,
      'Sởi': (base * 0.40).ceil() + 2,
      'Viêm não Nhật Bản': (base * 0.20).ceil() + 2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(title: 'Tạo kế hoạch tiêm lưu động', subtitle: 'Hệ thống tính số liều dự kiến từ số trẻ chưa tiêm đầy đủ và cộng mức dự phòng.'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _PlanForm(
              commune: _commune,
              date: _date,
              onCommuneChanged: (value) => setState(() {
                _commune = value;
                _calculated = false;
              }),
              onDateChanged: (value) => setState(() {
                _date = value;
                _calculated = false;
              }),
              onCalculate: () => setState(() => _calculated = true),
            );
            final result = _PlanResult(commune: _commune, date: _date, estimatedDoses: estimatedDoses, visible: _calculated);
            if (!wide) return Column(children: [form, const SizedBox(height: 16), result]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: 18), Expanded(child: result)]);
          },
        ),
      ],
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({required this.commune, required this.date, required this.onCommuneChanged, required this.onDateChanged, required this.onCalculate});

  final CommuneCoverage commune;
  final DateTime date;
  final ValueChanged<CommuneCoverage> onCommuneChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Thông tin buổi tiêm', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            DropdownButtonFormField<CommuneCoverage>(
              initialValue: commune,
              decoration: const InputDecoration(labelText: 'Xã mục tiêu', prefixIcon: Icon(Icons.location_on_outlined)),
              items: demoCoverage.map((item) => DropdownMenuItem(value: item, child: Text(item.name))).toList(),
              onChanged: (value) {
                if (value != null) onCommuneChanged(value);
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final result = await showDatePicker(context: context, firstDate: DateTime(2026, 7), lastDate: DateTime(2027, 12), initialDate: date);
                if (result != null) onDateChanged(result);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày tổ chức', prefixIcon: Icon(Icons.calendar_month_outlined)),
                child: Text(formatDate(date)),
              ),
            ),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Địa điểm', prefixIcon: Icon(Icons.home_work_outlined))),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onCalculate, icon: const Icon(Icons.calculate_outlined), label: const Text('Tính số liều cần mang')),
          ],
        ),
      ),
    );
  }
}

class _PlanResult extends StatelessWidget {
  const _PlanResult({required this.commune, required this.date, required this.estimatedDoses, required this.visible});

  final CommuneCoverage commune;
  final DateTime date;
  final Map<String, int> estimatedDoses;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: visible
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dự trù cho xã ${commune.name}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('${commune.missing} trẻ chưa tiêm đầy đủ • Ngày ${formatDate(date)}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  ...estimatedDoses.entries.map((entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(backgroundColor: softGreen, child: Icon(Icons.vaccines_rounded, color: primaryGreen)),
                        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text('${entry.value} liều', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      )),
                  const Divider(height: 28),
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu kế hoạch và mô phỏng gửi FCM cho cán bộ xã.'))),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu và gửi thông báo'),
                  ),
                ],
              )
            : const SizedBox(
                height: 310,
                child: EmptyState(title: 'Chưa có kết quả', description: 'Chọn xã, ngày tổ chức và nhấn nút tính số liều.'),
              ),
      ),
    );
  }
}
