import '../models/models.dart';

// ─────────────────────────────────────────────
// Lịch tiêm vaccine chuẩn quốc gia
// ─────────────────────────────────────────────

final demoSchedules = <VaccineSchedule>[
  const VaccineSchedule(
    id: 'BCG-1',
    vaccineName: 'BCG',
    doseNumber: 1,
    ageMonths: 0,
    toleranceDays: 30,
    description: 'Phòng bệnh lao, tiêm trong giai đoạn sơ sinh.',
  ),
  const VaccineSchedule(
    id: 'DPT-1',
    vaccineName: 'DPT',
    doseNumber: 1,
    ageMonths: 2,
    toleranceDays: 15,
    description: 'Bạch hầu, ho gà và uốn ván - mũi đầu tiên.',
  ),
  const VaccineSchedule(
    id: 'DPT-2',
    vaccineName: 'DPT',
    doseNumber: 2,
    ageMonths: 3,
    toleranceDays: 15,
    description: 'Bạch hầu, ho gà và uốn ván - mũi thứ hai.',
  ),
  const VaccineSchedule(
    id: 'DPT-3',
    vaccineName: 'DPT',
    doseNumber: 3,
    ageMonths: 4,
    toleranceDays: 15,
    description: 'Bạch hầu, ho gà và uốn ván - mũi thứ ba.',
  ),
  const VaccineSchedule(
    id: 'Sởi-1',
    vaccineName: 'Sởi',
    doseNumber: 1,
    ageMonths: 9,
    toleranceDays: 30,
    description: 'Mũi sởi đầu tiên khi trẻ đủ 9 tháng.',
  ),
  const VaccineSchedule(
    id: 'Viêm não Nhật Bản-1',
    vaccineName: 'Viêm não Nhật Bản',
    doseNumber: 1,
    ageMonths: 12,
    toleranceDays: 30,
    description: 'Phòng viêm não Nhật Bản.',
  ),
];

// ─────────────────────────────────────────────
// Danh mục thuốc uống
// ─────────────────────────────────────────────

final demoMedicationSchedules = <MedicationSchedule>[
  const MedicationSchedule(
    id: 'VIT-A-1',
    medicationName: 'Vitamin A liều cao (Đợt 1)',
    recommendedAge: '6 - 12 tháng',
    defaultDosage: '100.000 IU (1 viên)',
    description: 'Bổ sung Vitamin A phòng chống khô mắt và tăng sức đề kháng.',
  ),
  const MedicationSchedule(
    id: 'VIT-A-2',
    medicationName: 'Vitamin A liều cao (Đợt 2)',
    recommendedAge: '12 - 36 tháng',
    defaultDosage: '200.000 IU (1 viên)',
    description: 'Bổ sung định kỳ Vitamin A đợt 2 cho trẻ trên 1 tuổi.',
  ),
  const MedicationSchedule(
    id: 'TAY-GIUN-1',
    medicationName: 'Thuốc tẩy giun Mebendazole',
    recommendedAge: 'Từ 24 tháng',
    defaultDosage: '500 mg (1 viên)',
    description: 'Tẩy giun định kỳ 6 tháng/lần cho trẻ nhỏ.',
  ),
  const MedicationSchedule(
    id: 'OPV-ORAL-1',
    medicationName: 'Vaccine uống Bại liệt (OPV)',
    recommendedAge: '2 - 4 tháng',
    defaultDosage: '2 giọt',
    description: 'Vaccine phòng bệnh bại liệt đường uống.',
  ),
  const MedicationSchedule(
    id: 'VIT-K1',
    medicationName: 'Vitamin K1 dạng uống',
    recommendedAge: 'Sơ sinh',
    defaultDosage: '2 mg',
    description: 'Phòng xuất huyết xuất hiện sớm ở trẻ sơ sinh.',
  ),
];

// ─────────────────────────────────────────────
// Danh mục bệnh truyền nhiễm cần giám sát
// ─────────────────────────────────────────────

const demoDiseaseTypes = <DiseaseType>[
  DiseaseType(
    id: 'MEASLES',
    name: 'Sởi',
    symptoms: ['Sốt cao', 'Phát ban dạng sẩn', 'Ho', 'Chảy mũi', 'Mắt đỏ (viêm kết mạc)', 'Hạt Koplik trong miệng'],
    incubationDays: '7–21 ngày',
  ),
  DiseaseType(
    id: 'PERTUSSIS',
    name: 'Ho gà',
    symptoms: ['Ho kéo dài > 2 tuần', 'Ho cơn từng tràng', 'Tiếng rít khi hít vào', 'Nôn sau ho', 'Tím tái khi ho'],
    incubationDays: '5–21 ngày',
  ),
  DiseaseType(
    id: 'DIPHTHERIA',
    name: 'Bạch hầu',
    symptoms: ['Sốt nhẹ', 'Đau họng', 'Giả mạc trắng xám họng', 'Sưng hạch cổ (cổ bò)', 'Khàn tiếng'],
    incubationDays: '2–5 ngày',
  ),
  DiseaseType(
    id: 'CHOLERA',
    name: 'Tả (Tiêu chảy cấp)',
    symptoms: ['Tiêu chảy cấp ồ ạt', 'Phân nước trắng đục', 'Nôn mửa', 'Mất nước nhanh', 'Chuột rút'],
    incubationDays: '1–5 ngày',
  ),
  DiseaseType(
    id: 'CHICKENPOX',
    name: 'Thủy đậu',
    symptoms: ['Sốt nhẹ', 'Ban mụn nước toàn thân', 'Ngứa', 'Mệt mỏi', 'Đau đầu'],
    incubationDays: '10–21 ngày',
  ),
  DiseaseType(
    id: 'HAND_FOOT_MOUTH',
    name: 'Tay chân miệng',
    symptoms: ['Sốt', 'Loét miệng', 'Ban mụn nước ở tay', 'Ban mụn nước ở chân', 'Bỏ ăn / chảy dãi'],
    incubationDays: '3–7 ngày',
  ),
  DiseaseType(
    id: 'DENGUE',
    name: 'Sốt xuất huyết',
    symptoms: ['Sốt cao đột ngột', 'Đau đầu dữ dội', 'Đau cơ khớp', 'Xuất huyết dưới da', 'Chảy máu chân răng'],
    incubationDays: '4–10 ngày',
  ),
  DiseaseType(
    id: 'JE',
    name: 'Viêm não Nhật Bản',
    symptoms: ['Sốt cao', 'Đau đầu', 'Cứng gáy', 'Co giật', 'Rối loạn ý thức'],
    incubationDays: '5–15 ngày',
  ),
];

// ─────────────────────────────────────────────
// Helper: Tạo danh sách bản ghi tiêm chủng
// ─────────────────────────────────────────────

List<VaccinationRecord> _records(
  String childId,
  List<(String, String, int, String, String, String)> values,
) {
  return values.indexed.map((entry) {
    final index = entry.$1;
    final value = entry.$2;
    return VaccinationRecord(
      id: 'VR-$childId-$index',
      childId: childId,
      vaccineId: value.$1,
      vaccineName: value.$2,
      doseNumber: value.$3,
      lotNumber: value.$4,
      administeredBy: value.$5,
      administeredAt: DateTime.parse(value.$6),
      reactions: index == 1 ? 'Sốt nhẹ' : 'Không',
      reactionSeverity: index == 1 ? ReactionSeverity.mild : ReactionSeverity.none,
      storageTemperature: 4.5 + (index * 0.3), // giả lập nhiệt độ bảo quản hợp lệ
      syncStatus: SyncStatus.synced,
    );
  }).toList();
}

// ─────────────────────────────────────────────
// Dữ liệu demo: Danh sách trẻ em
// ─────────────────────────────────────────────

final demoChildren = <ChildProfile>[
  ChildProfile(
    id: 'CH001',
    qrCode: 'SP-TPH-24-0001',
    fullName: 'Nguyễn Minh An',
    dateOfBirth: DateTime(2024, 1, 15),
    gender: 'Nam',
    motherName: 'Nguyễn Thị Hoa',
    motherPhone: '0986 123 456',
    village: 'Bản Nậm Lùng',
    commune: 'Tả Phìn',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.late,
    nextVaccine: 'DPT - Mũi 3',
    nextDue: DateTime(2026, 7, 10),
    lateDays: 14,
    vaccinations: _records('CH001', [
      ('BCG-1', 'BCG', 1, 'BCG2401', 'Y sĩ Lê Thu', '2024-01-17'),
      ('DPT-1', 'DPT', 1, 'DPT2402', 'Y sĩ Lê Thu', '2024-03-18'),
      ('DPT-2', 'DPT', 2, 'DPT2403', 'Y sĩ Trần Nam', '2024-04-19'),
    ]),
    medications: [
      MedicationRecord(
        id: 'MR-CH001-1',
        childId: 'CH001',
        medicationId: 'VIT-A-1',
        medicationName: 'Vitamin A liều cao (Đợt 1)',
        dosage: '100.000 IU',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime(2024, 6, 1),
        syncStatus: SyncStatus.synced,
        notes: 'Trẻ dung nạp tốt, không dị ứng',
      ),
    ],
  ),
  ChildProfile(
    id: 'CH002',
    qrCode: 'SP-TVN-23-0002',
    fullName: 'Giàng Thị Mai',
    dateOfBirth: DateTime(2023, 11, 8),
    gender: 'Nữ',
    motherName: 'Giàng Thị Súa',
    motherPhone: '0977 220 118',
    village: 'Bản Séo Mý Tỷ',
    commune: 'Tả Van',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.dueSoon,
    nextVaccine: 'Sởi - Mũi 1',
    nextDue: DateTime(2026, 7, 30),
    lateDays: 0,
    vaccinations: _records('CH002', [
      ('BCG-1', 'BCG', 1, 'BCG2311', 'Y sĩ Lê Thu', '2023-11-10'),
      ('DPT-1', 'DPT', 1, 'DPT2401', 'Y sĩ Trần Nam', '2024-01-10'),
      ('DPT-2', 'DPT', 2, 'DPT2402', 'Y sĩ Trần Nam', '2024-02-11'),
      ('DPT-3', 'DPT', 3, 'DPT2403', 'Y sĩ Lê Thu', '2024-03-12'),
    ]),
    medications: [
      MedicationRecord(
        id: 'MR-CH002-1',
        childId: 'CH002',
        medicationId: 'VIT-A-1',
        medicationName: 'Vitamin A liều cao (Đợt 1)',
        dosage: '100.000 IU',
        administeredBy: 'Y sĩ Lê Thu',
        administeredAt: DateTime(2024, 6, 1),
        syncStatus: SyncStatus.synced,
      ),
      MedicationRecord(
        id: 'MR-CH002-2',
        childId: 'CH002',
        medicationId: 'VIT-A-2',
        medicationName: 'Vitamin A liều cao (Đợt 2)',
        dosage: '200.000 IU',
        administeredBy: 'Y sĩ Trần Nam',
        administeredAt: DateTime(2024, 12, 5),
        syncStatus: SyncStatus.synced,
      ),
    ],
  ),
  ChildProfile(
    id: 'CH003',
    qrCode: 'SP-LCH-22-0003',
    fullName: 'Lò Văn Bình',
    dateOfBirth: DateTime(2022, 8, 20),
    gender: 'Nam',
    motherName: 'Lò Thị Hương',
    motherPhone: '0968 441 230',
    village: 'Bản Lao Chải',
    commune: 'Lao Chải',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.complete,
    nextVaccine: 'Đã đủ mũi theo độ tuổi',
    nextDue: DateTime(2027, 1, 15),
    lateDays: 0,
    vaccinations: _records('CH003', [
      ('BCG-1', 'BCG', 1, 'BCG2208', 'Y sĩ Hà Linh', '2022-08-22'),
      ('DPT-1', 'DPT', 1, 'DPT2210', 'Y sĩ Hà Linh', '2022-10-20'),
      ('DPT-2', 'DPT', 2, 'DPT2211', 'Y sĩ Hà Linh', '2022-11-21'),
      ('DPT-3', 'DPT', 3, 'DPT2212', 'Y sĩ Hà Linh', '2022-12-22'),
      ('Sởi-1', 'Sởi', 1, 'SOI2305', 'Y sĩ Trần Nam', '2023-05-22'),
    ]),
    medications: [
      MedicationRecord(
        id: 'MR-CH003-1',
        childId: 'CH003',
        medicationId: 'TAY-GIUN-1',
        medicationName: 'Thuốc tẩy giun Mebendazole',
        dosage: '500 mg',
        administeredBy: 'Y sĩ Hà Linh',
        administeredAt: DateTime(2024, 9, 10),
        syncStatus: SyncStatus.synced,
      ),
    ],
  ),
  ChildProfile(
    id: 'CH004',
    qrCode: 'SP-HTH-24-0004',
    fullName: 'Sùng A Khánh',
    dateOfBirth: DateTime(2024, 4, 2),
    gender: 'Nam',
    motherName: 'Vàng Thị Dung',
    motherPhone: '0356 882 190',
    village: 'Bản Hầu Thào',
    commune: 'Hầu Thào',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.late,
    nextVaccine: 'DPT - Mũi 2',
    nextDue: DateTime(2026, 7, 3),
    lateDays: 21,
    vaccinations: _records('CH004', [
      ('BCG-1', 'BCG', 1, 'BCG2404', 'Y sĩ Lê Thu', '2024-04-04'),
      ('DPT-1', 'DPT', 1, 'DPT2406', 'Y sĩ Trần Nam', '2024-06-03'),
    ]),
  ),
  ChildProfile(
    id: 'CH005',
    qrCode: 'SP-SSH-25-0005',
    fullName: 'Tẩn Thị Ngọc',
    dateOfBirth: DateTime(2025, 1, 11),
    gender: 'Nữ',
    motherName: 'Tẩn Thị Lan',
    motherPhone: '0399 340 215',
    village: 'Bản Sín Chải',
    commune: 'San Sả Hồ',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.dueSoon,
    nextVaccine: 'DPT - Mũi 1',
    nextDue: DateTime(2026, 7, 29),
    lateDays: 0,
    vaccinations: _records('CH005', [
      ('BCG-1', 'BCG', 1, 'BCG2501', 'Y sĩ Hà Linh', '2025-01-13'),
    ]),
  ),
  ChildProfile(
    id: 'CH006',
    qrCode: 'SP-BHO-23-0006',
    fullName: 'Phàn Thị Mi',
    dateOfBirth: DateTime(2023, 6, 15),
    gender: 'Nữ',
    motherName: 'Phàn Thị Lý',
    motherPhone: '0869 128 992',
    village: 'Bản Bản Hồ',
    commune: 'Bản Hồ',
    district: 'Sa Pa',
    status: ChildVaccinationStatus.complete,
    nextVaccine: 'Đã đủ mũi theo độ tuổi',
    nextDue: DateTime(2027, 2, 1),
    lateDays: 0,
    vaccinations: _records('CH006', [
      ('BCG-1', 'BCG', 1, 'BCG2306', 'Y sĩ Hà Linh', '2023-06-16'),
      ('DPT-1', 'DPT', 1, 'DPT2308', 'Y sĩ Hà Linh', '2023-08-16'),
      ('DPT-2', 'DPT', 2, 'DPT2309', 'Y sĩ Hà Linh', '2023-09-18'),
      ('DPT-3', 'DPT', 3, 'DPT2310', 'Y sĩ Lê Thu', '2023-10-18'),
      ('Sởi-1', 'Sởi', 1, 'SOI2403', 'Y sĩ Lê Thu', '2024-03-16'),
    ]),
  ),
];

// ─────────────────────────────────────────────
// Dữ liệu demo: Tỷ lệ phủ vaccine theo xã
// ─────────────────────────────────────────────

const demoCoverage = <CommuneCoverage>[
  CommuneCoverage(name: 'Tả Phìn', total: 120, fully: 101, coverage: 84.2, bcg: 96, dpt1: 91, dpt2: 87, dpt3: 82),
  CommuneCoverage(name: 'Tả Van', total: 98, fully: 76, coverage: 77.6, bcg: 91, dpt1: 84, dpt2: 80, dpt3: 73),
  CommuneCoverage(name: 'Lao Chải', total: 145, fully: 124, coverage: 85.5, bcg: 97, dpt1: 92, dpt2: 88, dpt3: 83),
  CommuneCoverage(name: 'Hầu Thào', total: 86, fully: 48, coverage: 55.8, bcg: 83, dpt1: 70, dpt2: 59, dpt3: 51),
  CommuneCoverage(name: 'San Sả Hồ', total: 112, fully: 70, coverage: 62.5, bcg: 89, dpt1: 78, dpt2: 69, dpt3: 60),
  CommuneCoverage(name: 'Bản Hồ', total: 104, fully: 88, coverage: 84.6, bcg: 95, dpt1: 90, dpt2: 86, dpt3: 81),
];

// ─────────────────────────────────────────────
// Dữ liệu demo: Báo cáo dịch tễ
// ─────────────────────────────────────────────

final demoDiseaseReports = <DiseaseReport>[
  DiseaseReport(
    id: 'DR-001',
    diseaseTypeId: 'MEASLES',
    diseaseName: 'Sởi',
    patientName: 'Sùng A Khánh',
    patientAge: 27,  // 27 tháng tuổi
    patientGender: 'Nam',
    village: 'Bản Hầu Thào',
    commune: 'Hầu Thào',
    symptoms: ['Sốt cao', 'Phát ban dạng sẩn', 'Ho', 'Mắt đỏ (viêm kết mạc)'],
    onsetDate: DateTime(2026, 7, 20),
    reportedBy: 'Y sĩ Lê Thu',
    reportedAt: DateTime(2026, 7, 21),
    urgency: DiseaseUrgency.elevated,
    syncStatus: SyncStatus.synced,
    notes: 'Trẻ chưa tiêm mũi Sởi, sống cùng 3 trẻ khác trong gia đình. Đã cách ly tạm thời.',
    relatedChildId: 'CH004',
  ),
  DiseaseReport(
    id: 'DR-002',
    diseaseTypeId: 'HAND_FOOT_MOUTH',
    diseaseName: 'Tay chân miệng',
    patientName: 'Giàng A Páo',
    patientAge: 18,  // 18 tháng tuổi
    patientGender: 'Nam',
    village: 'Bản Séo Mý Tỷ',
    commune: 'Tả Van',
    symptoms: ['Sốt', 'Loét miệng', 'Ban mụn nước ở tay', 'Bỏ ăn / chảy dãi'],
    onsetDate: DateTime(2026, 7, 23),
    reportedBy: 'Y sĩ Trần Nam',
    reportedAt: DateTime(2026, 7, 23),
    urgency: DiseaseUrgency.routine,
    syncStatus: SyncStatus.synced,
    notes: 'Ca đơn lẻ, chưa phát hiện ca thứ 2 trong bản.',
  ),
  DiseaseReport(
    id: 'DR-003',
    diseaseTypeId: 'CHOLERA',
    diseaseName: 'Tả (Tiêu chảy cấp)',
    patientName: 'Lò Thị Hằng',
    patientAge: 4,  // 4 tuổi
    patientGender: 'Nữ',
    village: 'Bản Lao Chải',
    commune: 'Lao Chải',
    symptoms: ['Tiêu chảy cấp ồ ạt', 'Phân nước trắng đục', 'Nôn mửa', 'Mất nước nhanh'],
    onsetDate: DateTime(2026, 7, 24),
    reportedBy: 'Y sĩ Hà Linh',
    reportedAt: DateTime(2026, 7, 24),
    urgency: DiseaseUrgency.emergency,
    syncStatus: SyncStatus.pending,
    notes: 'KHẨN CẤP – Đã chuyển trẻ lên trạm y tế xã. Cần kiểm tra nguồn nước bản.',
  ),
];
