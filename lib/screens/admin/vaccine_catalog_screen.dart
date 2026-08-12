import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class VaccineCatalogScreen extends StatefulWidget {
  const VaccineCatalogScreen({super.key});

  @override
  State<VaccineCatalogScreen> createState() => _VaccineCatalogScreenState();
}

class _VaccineCatalogScreenState extends State<VaccineCatalogScreen> {
  int _selectedCatalog = 0; // 0: Vaccine, 1: Thuốc uống

  Future<void> _showAddVaccineDialog(BuildContext context, AppStore store) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddVaccineDialog(store: store),
    );
  }

  Future<void> _showAddMedicationDialog(BuildContext context, AppStore store) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddMedicationDialog(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader(
          title: 'Danh mục Y tế Chuẩn',
          subtitle: 'Dữ liệu chuẩn tiêm chủng và bổ sung thuốc đường uống cho trẻ em.',
          trailing: FilledButton.icon(
            onPressed: () {
              if (_selectedCatalog == 0) {
                _showAddVaccineDialog(context, store);
              } else {
                _showAddMedicationDialog(context, store);
              }
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
                rows: store.vaccineSchedules
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
                rows: store.medicationSchedules
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
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB9E6FE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lưu ý: Các thông tin và phác đồ liều dùng thuốc/vắc-xin được căn cứ chuẩn theo chương trình Tiêm chủng Mở rộng (TCMR) Quốc gia Việt Nam và các hướng dẫn y khoa lâm sàng chuẩn của Bộ Y tế.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dialog thêm Vaccine ──────────────────────────────────────────────────────

class _AddVaccineDialog extends StatefulWidget {
  const _AddVaccineDialog({required this.store});

  final AppStore store;

  @override
  State<_AddVaccineDialog> createState() => _AddVaccineDialogState();
}

class _AddVaccineDialogState extends State<_AddVaccineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedDose = 1;
  int _selectedAgeMonths = 0;
  int _selectedToleranceDays = 30;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateId(String name, int dose) {
    final sanitized = name.trim().replaceAll(' ', '-');
    return '$sanitized-$dose';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final name = _nameController.text.trim();
    final dose = _selectedDose;
    final ageMonths = _selectedAgeMonths;
    final toleranceDays = _selectedToleranceDays;

    // Kiểm tra trùng
    final isDuplicate = widget.store.vaccineSchedules.any(
      (s) => s.vaccineName.toLowerCase() == name.toLowerCase() && s.doseNumber == dose,
    );
    if (isDuplicate) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccine và số mũi này đã tồn tại trong danh mục!'),
            backgroundColor: Color(0xFFB42318),
          ),
        );
      }
      return;
    }

    final newSchedule = VaccineSchedule(
      id: _generateId(name, dose),
      vaccineName: name,
      doseNumber: dose,
      ageMonths: ageMonths,
      toleranceDays: toleranceDays,
      description: _descriptionController.text.trim(),
    );

    widget.store.addVaccineSchedule(newSchedule);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${newSchedule.vaccineName} - Mũi ${newSchedule.doseNumber}" vào danh mục vaccine.'),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.vaccines_rounded, color: primaryGreen),
          SizedBox(width: 10),
          Text('Thêm lịch Vaccine mới'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên Vaccine *',
                    hintText: 'Ví dụ: Viêm gan B, Sởi - Quai bị...',
                    prefixIcon: Icon(Icons.vaccines_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Vui lòng nhập tên vaccine';
                    if (v!.trim().length < 2) return 'Tên vaccine phải có ít nhất 2 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedDose,
                        decoration: const InputDecoration(
                          labelText: 'Số mũi *',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        items: const [1, 2, 3, 4, 5]
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDose = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedAgeMonths,
                        decoration: const InputDecoration(
                          labelText: 'Tuổi tiêm *',
                          prefixIcon: Icon(Icons.child_care_outlined),
                        ),
                        items: const [0, 1, 2, 3, 4, 5, 6, 9, 12, 18, 24, 36, 48, 60]
                            .map((m) {
                              final text = m == 0 ? '0 (Sơ sinh)' : '$m tháng';
                              return DropdownMenuItem(value: m, child: Text(text));
                            })
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAgeMonths = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedToleranceDays,
                  decoration: const InputDecoration(
                    labelText: 'Dung sai (ngày) *',
                    prefixIcon: Icon(Icons.timelapse_outlined),
                  ),
                  items: const [7, 15, 30, 45, 60, 90]
                      .map((t) => DropdownMenuItem(value: t, child: Text('± $t ngày')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedToleranceDays = val);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Công dụng, lưu ý đặc biệt...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_rounded),
          label: const Text('Thêm vaccine'),
        ),
      ],
    );
  }
}

// ── Dialog thêm Thuốc uống & Bổ sung ─────────────────────────────────────────

class _AddMedicationDialog extends StatefulWidget {
  const _AddMedicationDialog({required this.store});

  final AppStore store;

  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedAge = '6 - 12 tháng';
  String _selectedDosage = '200.000 IU (1 viên)';

  final _ageFrames = [
    'Sơ sinh (0 - 6 tháng)',
    '6 - 12 tháng',
    '12 - 24 tháng',
    'Từ 24 tháng trở lên',
    'Từ 36 tháng trở lên',
    'Từ 60 tháng trở lên',
    'Mọi lứa tuổi',
  ];

  final _dosageFrames = [
    '100.000 IU (1 viên)',
    '200.000 IU (1 viên)',
    '1 giọt / ngày',
    '2 giọt / ngày',
    '5 ml / ngày',
    '1 viên / ngày',
    '2 viên / ngày',
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateId(String name) {
    return name.trim().toUpperCase().replaceAll(' ', '-').substring(0, name.trim().length.clamp(0, 12));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final name = _nameController.text.trim();
    final age = _selectedAge;
    final dosage = _selectedDosage;

    // Kiểm tra trùng
    final isDuplicate = widget.store.medicationSchedules.any(
      (s) => s.medicationName.toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thuốc / bổ sung này đã tồn tại trong danh mục!'),
            backgroundColor: Color(0xFFB42318),
          ),
        );
      }
      return;
    }

    final newSchedule = MedicationSchedule(
      id: '${_generateId(name)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      medicationName: name,
      recommendedAge: age,
      defaultDosage: dosage,
      description: _descriptionController.text.trim(),
    );

    widget.store.addMedicationSchedule(newSchedule);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${newSchedule.medicationName}" vào danh mục thuốc uống & bổ sung.'),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.medication_rounded, color: primaryGreen),
          SizedBox(width: 10),
          Text('Thêm Thuốc uống / Bổ sung'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thuốc / Bổ sung *',
                    hintText: 'Ví dụ: Vitamin D3, Sắt uống...',
                    prefixIcon: Icon(Icons.medication_liquid_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Vui lòng nhập tên thuốc';
                    if (v!.trim().length < 3) return 'Tên thuốc phải có ít nhất 3 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedAge,
                  decoration: const InputDecoration(
                    labelText: 'Độ tuổi khuyến nghị *',
                    prefixIcon: Icon(Icons.child_care_outlined),
                  ),
                  items: _ageFrames.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAge = val);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedDosage,
                  decoration: const InputDecoration(
                    labelText: 'Liều dùng chuẩn *',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  items: _dosageFrames.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDosage = val);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Công dụng, lưu ý sử dụng...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_rounded),
          label: const Text('Thêm thuốc'),
        ),
      ],
    );
  }
}
