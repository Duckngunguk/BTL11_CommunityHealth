import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class ChildFormScreen extends StatefulWidget {
  const ChildFormScreen({super.key, this.childToEdit});

  final ChildProfile? childToEdit;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _motherPhoneController;
  late final TextEditingController _districtController;
  late final TextEditingController _qrCodeController;

  late DateTime _dob;
  late String _gender;
  late String _selectedCommune;
  late String _selectedVillage;

  bool get _isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    final child = widget.childToEdit;
    _fullNameController = TextEditingController(text: child?.fullName ?? '');
    _motherNameController = TextEditingController(text: child?.motherName ?? '');
    _motherPhoneController = TextEditingController(text: child?.motherPhone ?? '');
    _districtController = TextEditingController(text: child?.district ?? 'Sa Pa');
    _qrCodeController = TextEditingController(text: child?.qrCode ?? '');

    _dob = child?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 90));
    _gender = child?.gender ?? 'Nam';

    // Cascade dropdown values initialization
    _selectedCommune = child?.commune ?? 'Tả Phìn';
    _selectedVillage = child?.village ?? 'Bản Nậm Lùng';
    if (!kVillagesByCommune.containsKey(_selectedCommune)) {
      _selectedCommune = 'Tả Phìn';
    }
    if (!kVillagesByCommune[_selectedCommune]!.contains(_selectedVillage)) {
      _selectedVillage = kVillagesByCommune[_selectedCommune]!.first;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _districtController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final store = AppScope.of(context);
    final fullName = _fullNameController.text.trim();
    final motherName = _motherNameController.text.trim();
    final motherPhone = _motherPhoneController.text.trim();
    final village = _selectedVillage;
    final commune = _selectedCommune;
    final district = _districtController.text.trim();
    String qrCode = _qrCodeController.text.trim();

    if (_isEditing) {
      final updated = widget.childToEdit!.copyWith(
        fullName: fullName,
        dateOfBirth: _dob,
        gender: _gender,
        motherName: motherName,
        motherPhone: motherPhone,
        village: village,
        commune: commune,
        district: district,
        qrCode: qrCode.isEmpty ? widget.childToEdit!.qrCode : qrCode,
      );
      store.updateChild(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin trẻ thành công.')),
      );
    } else {
      final newIndex = (store.children.length + 1).toString().padLeft(3, '0');
      final newId = 'CH$newIndex';
      if (qrCode.isEmpty) {
        qrCode = 'CH-QR-$newIndex';
      }

      final newChild = ChildProfile(
        id: newId,
        qrCode: qrCode,
        fullName: fullName,
        dateOfBirth: _dob,
        gender: _gender,
        motherName: motherName,
        motherPhone: motherPhone,
        village: village,
        commune: commune,
        district: district,
        status: ChildVaccinationStatus.dueSoon,
        nextVaccine: 'DPT - Mũi 1',
        nextDue: DateTime.now().add(const Duration(days: 7)),
        lateDays: 0,
        vaccinations: [],
        medications: [],
      );

      store.addChild(newChild);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm trẻ mới vào sổ theo dõi.')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.blueAccent, fontSize: 15)),
        ),
        title: Text(_isEditing ? 'Sửa thông tin trẻ' : 'Tạo hồ sơ trẻ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Lưu' : 'Xong', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
          label: Text(_isEditing ? 'Lưu thay đổi' : 'Tạo hồ sơ lưu trữ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên trẻ em *',
                hintText: 'Nhập họ tên đầy đủ',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ tên trẻ' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                        initialDate: _dob,
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày tháng năm sinh *',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDate(_dob)),
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Giới tính *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _gender = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('commune-$_selectedCommune'),
                    value: _selectedCommune,
                    decoration: const InputDecoration(
                      labelText: 'Xã cư trú *',
                    ),
                    items: kVillagesByCommune.keys.map((commune) => DropdownMenuItem(
                      value: commune,
                      child: Text(commune),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCommune = val;
                          _selectedVillage = kVillagesByCommune[val]!.first;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('village-$_selectedCommune-$_selectedVillage'),
                    value: _selectedVillage,
                    decoration: const InputDecoration(
                      labelText: 'Địa bàn cư trú (Thôn bản) *',
                    ),
                    items: kVillagesByCommune[_selectedCommune]!.map((village) => DropdownMenuItem(
                      value: village,
                      child: Text(village),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedVillage = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(
                labelText: 'Họ tên cha / mẹ / Người giám hộ *',
                hintText: 'Nhập tên phụ huynh',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên mẹ / giám hộ' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _motherPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ khẩn cấp',
                hintText: 'Ví dụ: 0987654321',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'Huyện / Thị xã *',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập huyện' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _qrCodeController,
              decoration: const InputDecoration(
                labelText: 'Mã QR / Mã định danh (Không bắt buộc)',
                hintText: 'Tự động tạo nếu để trống',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

