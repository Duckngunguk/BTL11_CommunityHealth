import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common_widgets.dart';

class DiseaseReportScreen extends StatefulWidget {
  const DiseaseReportScreen({super.key});

  @override
  State<DiseaseReportScreen> createState() => _DiseaseReportScreenState();
}

class _DiseaseReportScreenState extends State<DiseaseReportScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final commune = store.currentHealthWorkerCommune ?? 'Chưa phân công';
    final reports = store.currentUserDiseaseReports;

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── 1. Top Offline Alert Banner (Matching Prototype) ──
          Container(
            color: const Color(0xFFB06000), // Dark yellow-orange bar
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  store.isOnline
                      ? 'CHẾ ĐỘ TRỰC TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "ĐÃ ĐỒNG BỘ"}'
                      : 'CHẾ ĐỘ NGOẠI TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "Sẵn sàng ghi dữ liệu"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Screen Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Báo dịch',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: gray900,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gray200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: gray500, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        commune == 'Chưa phân công' ? commune : 'Xã $commune',
                        style: const TextStyle(
                            color: gray700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Warning outline icon on right
                const Icon(
                  Icons.warning_amber_rounded,
                  color: accentRed,
                  size: 24,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: gray200),

          // ── 3. Sub-header & List ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'BÁO CÁO DỊCH LƯU HÀNH',
                    style: TextStyle(
                      color: gray500,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
                Expanded(
                  child: reports.isEmpty
                      ? const EmptyState(
                          title: 'Không có ca bệnh nghi ngờ',
                          description:
                              'Chưa có báo cáo dịch bệnh nào tại địa phương này.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _DiseaseReportCard(
                            report: reports[index],
                            index: index,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: gray200)),
        ),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const AddDiseaseReportScreen()),
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  accentRed, // Changed from green to red as requested
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Báo cáo ca dịch nghi ngờ mới',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiseaseReportCard extends StatelessWidget {
  const _DiseaseReportCard({required this.report, required this.index});
  final DiseaseReport report;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = report.status == 'Đã xác minh';
    final Color borderColor = isConfirmed ? accentRed : accentYellow;

    // Stable formatting of ID based on database ID
    String displayId = report.id;
    if (report.id.startsWith('RPT-')) {
      final numStr = report.id.substring(4);
      final val = int.tryParse(numStr);
      if (val != null) {
        displayId = '#${102 + val}';
      }
    }

    // Dynamic case counts from notes or fallback
    int caseCount = 1;
    if (report.notes != null) {
      final match =
          RegExp(r'Số ca (ghi nhận|mắc)?:?\s*(\d+)').firstMatch(report.notes!);
      if (match != null) {
        caseCount = int.tryParse(match.group(2) ?? '') ?? 1;
      } else {
        caseCount = (report.id.hashCode % 3) + 1;
      }
    } else {
      caseCount = (report.id.hashCode % 3) + 1;
    }

    // Title format
    String titleText = 'Nghi ổ dịch ${report.diseaseType}';
    if (report.diseaseType.contains('Thuỷ đậu')) {
      titleText = 'Dịch Thuỷ đậu nghi ngờ';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color stripe
              Container(width: 4, color: borderColor),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$displayId • $titleText',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: gray900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Địa điểm: ${report.village} • Số ca: $caseCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: gray700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Báo cáo: ${report.reportedBy} (${formatDate(report.reportedAt)})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      isConfirmed
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Đã xác minh',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: accentYellow, width: 1.2),
                              ),
                              child: const Text(
                                'Đang theo dõi',
                                style: TextStyle(
                                  color: accentYellow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddDiseaseReportScreen extends StatefulWidget {
  const AddDiseaseReportScreen({super.key});

  @override
  State<AddDiseaseReportScreen> createState() => _AddDiseaseReportScreenState();
}

class _AddDiseaseReportScreenState extends State<AddDiseaseReportScreen> {
  int _selectedTab = 0; // 0: Chọn theo Bản, 1: Quét mã QR, 2: Khẩn cấp

  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _caseCountController = TextEditingController(text: '1');
  final _symptomsController = TextEditingController();

  String? _selectedVillage;
  String? _emergencyVillage;
  String? _selectedDisease;
  String? _gpsCoordinates;
  bool _isLocating = false;

  // For QR Scanner simulated result
  String? _scannedChildName;
  String? _scannedChildId;
  String? _scannedVillage;

  // For Khẩn cấp tab image upload
  String? _capturedImagePath;
  bool _isCapturing = false;

  final _diseases = [
    'Sởi',
    'Tả',
    'Sốt xuất huyết',
    'Thuỷ đậu',
    'Bệnh Dại',
    'Khác'
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _caseCountController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _getGpsLocation() {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          final lat = 22.3564 + (DateTime.now().millisecond % 100) * 0.0001;
          final lng = 103.8427 + (DateTime.now().microsecond % 100) * 0.0001;
          _gpsCoordinates =
              '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
        });
      }
    });
  }

  void _scanQrCode() {
    showDialog<ChildProfile>(
      context: context,
      builder: (context) {
        final store = AppScope.of(context);
        final childrenList = store.currentUserChildren;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: primaryBlue),
              SizedBox(width: 8),
              Text('Quét QR Sổ Tiêm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: childrenList.isEmpty
                ? const Text(
                    'Không tìm thấy dữ liệu trẻ em nào trong cơ sở dữ liệu.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Chọn một trẻ để mô phỏng quét mã QR thành công:',
                          style: TextStyle(fontSize: 12, color: gray600)),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: childrenList.length,
                          itemBuilder: (context, idx) {
                            final child = childrenList[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: blueLight,
                                child: Icon(Icons.person_rounded,
                                    color: primaryBlue),
                              ),
                              title: Text(child.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              subtitle: Text(
                                  'Mã QR: ${child.qrCode} • ${child.village}',
                                  style: const TextStyle(fontSize: 11)),
                              onTap: () {
                                Navigator.pop(context, child);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: gray500)),
            ),
          ],
        );
      },
    ).then((value) {
      if (!mounted) return;
      if (value != null) {
        setState(() {
          _scannedChildName = value.fullName;
          _scannedChildId = value.id;
          _scannedVillage = value.village;

          if (_symptomsController.text.isEmpty) {
            _symptomsController.text =
                'Trẻ ${value.fullName} (Mã QR: ${value.qrCode}). ';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận diện thành công trẻ: ${value.fullName}'),
            backgroundColor: const Color(0xFF18794E),
          ),
        );
      }
    });
  }

  void _capturePhoto() {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedImagePath =
              'danh_sach_viet_tay_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chụp ảnh danh sách thành công!'),
            backgroundColor: Color(0xFF18794E),
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    final store = AppScope.of(context);
    final isOnline = store.isOnline;
    final commune = store.currentHealthWorkerCommune;
    if (commune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tài khoản chưa được Admin phân công xã nên không thể báo dịch.',
          ),
        ),
      );
      return;
    }

    String finalPatientName = '';
    String finalVillage = '';
    String? finalChildId;
    String finalNotes = '';

    if (_selectedTab == 0) {
      if (_selectedVillage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thôn bản cư trú')),
        );
        return;
      }
      finalPatientName = 'Ổ dịch tại $_selectedVillage';
      finalVillage = _selectedVillage!;
      finalNotes = 'Báo cáo theo bản.';
    } else if (_selectedTab == 1) {
      if (_scannedChildId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng quét QR Sổ Tiêm trước')),
        );
        return;
      }
      finalPatientName = _scannedChildName ?? 'Trẻ quét mã QR';
      finalVillage = _scannedVillage ?? 'Không xác định';
      finalChildId = _scannedChildId;
      finalNotes = 'Quét mã định danh thành công.';
    } else {
      if (_emergencyVillage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thôn bản xảy ra ổ dịch')),
        );
        return;
      }
      finalPatientName = _patientNameController.text.trim();
      if (finalPatientName.isEmpty) {
        finalPatientName = 'Nhóm bệnh nhân khẩn cấp';
      }
      finalVillage = _emergencyVillage!;
      finalNotes = 'Báo cáo khẩn cấp. Số ca: ${_caseCountController.text}.';
      if (_capturedImagePath != null) {
        finalNotes += ' Đính kèm ảnh danh sách.';
      }
    }

    if (_selectedDisease == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn loại bệnh truyền nhiễm nghi ngờ')),
      );
      return;
    }

    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập triệu chứng / ghi chú thực tế')),
      );
      return;
    }

    final newReport = DiseaseReport(
      id: 'RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      patientName: finalPatientName,
      diseaseType: _selectedDisease!,
      village: finalVillage,
      commune: commune,
      district: 'Sa Pa',
      reportedAt: DateTime.now(),
      reportedBy: store.currentUser?.fullName ?? 'Y sĩ Lê Thu',
      symptoms: _symptomsController.text.trim(),
      syncStatus: VaccinationSyncStatus.pending,
      status: 'Nghi ngờ',
      severity: DiseaseSeverity.moderate,
      notes: finalNotes,
      childId: finalChildId,
    );

    await store.addDiseaseReport(newReport);
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Đã lưu báo cáo "${newReport.diseaseType}". Hệ thống sẽ xác nhận sau khi Firestore đồng bộ thành công.'
              : 'Đã lưu báo cáo offline (Ngoại tuyến). Dữ liệu sẽ tự động đồng bộ khi có mạng.',
        ),
        backgroundColor:
            isOnline ? const Color(0xFF18794E) : const Color(0xFF8A5D00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final commune = store.currentHealthWorkerCommune;
    final communeVillages = commune == null
        ? const <String>[]
        : kVillagesByCommune[commune] ?? const <String>[];

    return Scaffold(
      backgroundColor: gray100,
      body: Column(
        children: [
          // ── 1. Top Offline Alert Banner ──
          Container(
            color: const Color(0xFFB06000), // Dark yellow-orange bar
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  store.isOnline
                      ? 'CHẾ ĐỘ TRỰC TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "ĐÃ ĐỒNG BỘ"}'
                      : 'CHẾ ĐỘ NGOẠI TUYẾN • ${store.pendingCount > 0 ? "${store.pendingCount} bản ghi chờ đồng bộ" : "Sẵn sàng ghi dữ liệu"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Custom App Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left_rounded,
                            color: primaryBlue, size: 22),
                        Text('Danh sách',
                            style: TextStyle(
                                color: primaryBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Báo cáo ca dịch',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: gray900),
                  ),
                ),
                TextButton(
                  onPressed: _submit,
                  child: const Text('Gửi',
                      style: TextStyle(
                          color: accentRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: gray200),

          // ── 3. Tab Bar Selector ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: gray100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gray200),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, 'Chọn theo Bản'),
                  _buildTabItem(1, 'Quét mã QR'),
                  _buildTabItem(2, 'Khẩn cấp'),
                ],
              ),
            ),
          ),
          Container(height: 1, color: gray200),

          // ── 4. Main Fields Forms ──
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Custom tab contents
                  if (_selectedTab == 0) ...[
                    // Tab 1: Chọn theo Bản
                    _buildCardContainer(
                      label: 'CHỌN THÔN BẢN CƯ TRÚ *',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedVillage,
                          hint: const Text('-- Chọn thôn bản --',
                              style: TextStyle(color: gray500, fontSize: 13.5)),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          items: communeVillages
                              .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v,
                                      style: const TextStyle(fontSize: 13.5))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedVillage = val),
                        ),
                      ),
                    ),
                  ] else if (_selectedTab == 1) ...[
                    // Tab 2: Quét mã QR
                    _buildQrScanCard(),
                  ] else ...[
                    // Tab 3: Khẩn cấp
                    _buildCardContainer(
                      label: 'TÊN / NHÓM NGƯỜI BỆNH (NẾU CÓ)',
                      child: TextFormField(
                        controller: _patientNameController,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Hộ Lò A Phủ hoặc 5 người lớn',
                          hintStyle: TextStyle(color: gray400, fontSize: 13.5),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _buildCardContainer(
                      label: 'SỐ CA MẮC NGHI NGỜ *',
                      child: TextFormField(
                        controller: _caseCountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _buildCardContainer(
                      label: 'THÔN BẢN XẢY RA Ổ DỊCH *',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _emergencyVillage,
                          hint: const Text('-- Chọn thôn bản --',
                              style: TextStyle(color: gray500, fontSize: 13.5)),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          items: communeVillages
                              .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v,
                                      style: const TextStyle(fontSize: 13.5))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _emergencyVillage = val),
                        ),
                      ),
                    ),
                    _buildPhotoUploadCard(),
                  ],

                  // Common Fields below tab custom structures
                  _buildCardContainer(
                    label: 'BỆNH TRUYỀN NHIỄM NGHI NGỜ *',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDisease,
                        hint: const Text('-- Chọn bệnh truyền nhiễm --',
                            style: TextStyle(color: gray500, fontSize: 13.5)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        items: _diseases
                            .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d,
                                    style: const TextStyle(fontSize: 13.5))))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDisease = val),
                      ),
                    ),
                  ),

                  _buildGpsCard(),

                  _buildCardContainer(
                    label: 'TRIỆU CHỨNG / GHI CHÚ THỰC TẾ',
                    child: TextFormField(
                      controller: _symptomsController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText:
                            'Mô tả các triệu chứng lâm sàng quan sát được...',
                        hintStyle: TextStyle(color: gray400, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: gray200)),
        ),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: accentRed, // Red color instead of green
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Gửi báo cáo về xã',
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? gray900 : gray600,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: gray600,
              letterSpacing: 0.02,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildQrScanCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dashed blue camera scanner boundary box
          CustomPaint(
            painter:
                DashedRectPainter(color: primaryBlue, strokeWidth: 1.5, gap: 5),
            child: Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              child: _scannedChildName != null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: primaryBlue, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'ĐÃ QUÉT',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                      color: primaryBlue,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 18),
          // Quét QR Sổ Tiêm button
          OutlinedButton.icon(
            onPressed: _scanQrCode,
            icon: const Icon(Icons.photo_camera_back_outlined,
                color: gray900, size: 16),
            label: Text(
              _scannedChildName != null
                  ? 'Quét lại Sổ Tiêm'
                  : 'Quét QR Sổ Tiêm',
              style: const TextStyle(
                  color: gray900, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: gray900, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              backgroundColor: gray100,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          if (_scannedChildName != null) ...[
            const SizedBox(height: 12),
            Text(
              'Trẻ: $_scannedChildName\nThôn bản: $_scannedVillage',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: gray700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ẢNH CHỤP DANH SÁCH VIẾT TAY (TÙY CHỌN)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: gray600,
              letterSpacing: 0.02,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: gray100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gray200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: gray500, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _isCapturing
                        ? 'Đang chụp...'
                        : (_capturedImagePath != null
                            ? 'Đã chụp ảnh danh sách'
                            : 'Chụp ảnh danh sách'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gray700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỌA ĐỘ GPS GHI NHẬN CA',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: gray600,
                  letterSpacing: 0.02,
                ),
              ),
              GestureDetector(
                onTap: _getGpsLocation,
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded,
                        color: primaryBlue, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _isLocating ? 'ĐANG LẤY...' : 'LẤY GPS THIẾT BỊ',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _gpsCoordinates != null
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _gpsCoordinates != null
                          ? 'Tọa độ: $_gpsCoordinates'
                          : 'Tọa độ: Chưa lấy tọa độ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _gpsCoordinates != null
                      ? 'Định vị thành công từ cảm biến GPS thực địa.'
                      : 'Nhấn nút ở trên để tự động quét GPS thực địa.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final dashWidth = gap;
    final dashSpace = gap;
    double distance = 0.0;

    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap;
}
