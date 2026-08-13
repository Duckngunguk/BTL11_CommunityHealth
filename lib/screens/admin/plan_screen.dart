import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  String? _selectedCommuneName;
  DateTime _date = DateTime(2026, 8, 20);
  bool _calculated = false;
  String? _selectedWorkerId;
  final _locationController = TextEditingController(text: 'Trạm Y tế xã');

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Map<String, int> _calculateEstimatedDoses(CommuneCoverage commune) {
    final base = commune.missing;
    return {
      'BCG': (base * 0.25).ceil() + 2,
      'DPT': (base * 0.70).ceil() + 4,
      'Sởi': (base * 0.40).ceil() + 2,
      'Viêm não Nhật Bản': (base * 0.20).ceil() + 2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final communesList = store.communeCoverage;
    final healthWorkers = store.users.where((u) => u.role == UserRole.healthWorker).toList();

    final currentCommune = communesList.firstWhere(
      (c) => c.name == _selectedCommuneName,
      orElse: () => communesList.isNotEmpty ? communesList.first : const CommuneCoverage(name: 'Tả Phìn', total: 0, fully: 0, coverage: 0, bcg: 0, dpt1: 0, dpt2: 0, dpt3: 0),
    );

    final currentWorker = healthWorkers.firstWhere(
      (w) => w.id == _selectedWorkerId,
      orElse: () => healthWorkers.isNotEmpty ? healthWorkers.first : UserModel(id: 'none', username: 'none', fullName: 'Không có cán bộ', email: '', phone: '', role: UserRole.healthWorker, status: UserAccountStatus.active, createdAt: DateTime.now()),
    );

    final estimatedDoses = _calculateEstimatedDoses(currentCommune);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'Kế hoạch tiêm lưu động',
          subtitle: 'Hệ thống tự động tính dự trù số liều vaccine dựa trên số lượng trẻ chưa tiêm chủng đầy đủ tại thực địa xã.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _PlanForm(
              communeName: currentCommune.name,
              date: _date,
              locationController: _locationController,
              selectedWorkerId: currentWorker.id,
              communesList: communesList,
              healthWorkers: healthWorkers,
              onCommuneNameChanged: (value) => setState(() {
                _selectedCommuneName = value;
                _calculated = false;
              }),
              onDateChanged: (value) => setState(() {
                _date = value;
                _calculated = false;
              }),
              onWorkerChanged: (value) => setState(() {
                _selectedWorkerId = value;
                _calculated = false;
              }),
              onCalculate: () => setState(() => _calculated = true),
            );

            final result = _PlanResult(
              commune: currentCommune,
              date: _date,
              location: _locationController.text,
              worker: currentWorker.id != 'none' ? currentWorker : null,
              estimatedDoses: estimatedDoses,
              visible: _calculated,
              onSave: () async {
                final newPlan = VaccinePlan(
                  id: 'PLN-${DateTime.now().millisecondsSinceEpoch}',
                  communeName: currentCommune.name,
                  date: _date,
                  location: _locationController.text,
                  workerName: currentWorker.id != 'none' ? currentWorker.fullName : 'Chưa phân công',
                  estimatedDoses: Map<String, int>.from(estimatedDoses),
                  createdAt: DateTime.now(),
                );
                await store.addVaccinePlan(newPlan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã phát lệnh tiêm chủng lưu động tại xã ${currentCommune.name}!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
                setState(() {
                  _calculated = false;
                  _locationController.text = 'Trạm Y tế xã';
                });
              },
            );

            if (!wide) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  result,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: 20),
                Expanded(child: result),
              ],
            );
          },
        ),
        
        // Lịch sử kế hoạch đã lập
        if (store.vaccinePlans.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history_edu_outlined, color: Colors.purple.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'LỊCH SỬ KẾ HOẠCH ĐÃ PHÁT LỆNH',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.vaccinePlans.length,
            itemBuilder: (context, index) {
              final plan = store.vaccinePlans[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Kế hoạch tại Xã ${plan.communeName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Đã phát lệnh',
                                style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('Địa điểm: ${plan.location}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(width: 20),
                            Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('Ngày thực hiện: ${formatDate(plan.date)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('Cán bộ phụ trách: ${plan.workerName}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 20),
                        Wrap(
                          spacing: 12,
                          children: plan.estimatedDoses.entries.map((e) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.vaccines_outlined, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text('${e.key}: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('${e.value} liều', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({
    required this.communeName,
    required this.date,
    required this.locationController,
    required this.selectedWorkerId,
    required this.communesList,
    required this.healthWorkers,
    required this.onCommuneNameChanged,
    required this.onDateChanged,
    required this.onWorkerChanged,
    required this.onCalculate,
  });

  final String communeName;
  final DateTime date;
  final TextEditingController locationController;
  final String selectedWorkerId;
  final List<CommuneCoverage> communesList;
  final List<UserModel> healthWorkers;
  final ValueChanged<String> onCommuneNameChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onWorkerChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings_outlined, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Thông số buổi tiêm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: communesList.any((c) => c.name == communeName) ? communeName : (communesList.isNotEmpty ? communesList.first.name : null),
              decoration: const InputDecoration(
                labelText: 'Xã mục tiêu',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              items: communesList.map((item) => DropdownMenuItem(value: item.name, child: Text(item.name))).toList(),
              onChanged: (value) {
                if (value != null) onCommuneNameChanged(value);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2026, 7),
                  lastDate: DateTime(2027, 12),
                  initialDate: date,
                );
                if (result != null) onDateChanged(result);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày tổ chức',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(formatDate(date), style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Địa điểm tổ chức cụ thể',
                prefixIcon: Icon(Icons.home_work_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: healthWorkers.any((w) => w.id == selectedWorkerId) ? selectedWorkerId : (healthWorkers.isNotEmpty ? healthWorkers.first.id : null),
              decoration: const InputDecoration(
                labelText: 'Cán bộ Y tế phụ trách',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: healthWorkers.map((w) {
                final communeText = w.assignedCommune != null ? ' (Xã ${w.assignedCommune})' : '';
                return DropdownMenuItem(
                  value: w.id,
                  child: Text('${w.fullName}$communeText'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onWorkerChanged(value);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCalculate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.blue.shade700,
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Tính dự phóng số liều', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanResult extends StatelessWidget {
  const _PlanResult({
    required this.commune,
    required this.date,
    required this.location,
    required this.worker,
    required this.estimatedDoses,
    required this.visible,
    required this.onSave,
  });

  final CommuneCoverage commune;
  final DateTime date;
  final String location;
  final UserModel? worker;
  final Map<String, int> estimatedDoses;
  final bool visible;
  final VoidCallback onSave;

  Color _getVaccineColor(String name) {
    switch (name) {
      case 'BCG':
        return Colors.blue;
      case 'DPT':
        return Colors.green;
      case 'Sởi':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: visible
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.analytics_outlined, color: Colors.green.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Kết quả dự trù', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Xã mục tiêu: ${commune.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Địa điểm: $location', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  Text('Ngày dự kiến: ${formatDate(date)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Phát hiện ${commune.missing} trẻ chưa tiêm đủ mũi tại địa bàn.',
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (worker != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.person, color: Colors.blue.shade700),
                      ),
                      title: Text(worker!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Cán bộ phụ trách • SĐT: ${worker!.phone}', style: const TextStyle(fontSize: 12)),
                    ),
                    const Divider(height: 24),
                  ],
                  const Text('Dự toán số liều cần mang theo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...estimatedDoses.entries.map((entry) {
                    final color = _getVaccineColor(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.vaccines_outlined, color: color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            Text(
                              '${entry.value} liều',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Lưu & Phát lệnh tiêm chủng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            : const SizedBox(
                height: 350,
                child: EmptyState(
                  title: 'Chưa có kết quả dự trù',
                  description: 'Chọn các thông số buổi tiêm bên trái và bấm nút "Tính dự phóng số liều" để nhận kết quả ước lượng.',
                ),
              ),
      ),
    );
  }
}
