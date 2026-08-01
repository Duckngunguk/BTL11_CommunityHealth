// ─────────────────────────────────────────────
// Enums dùng chung
// ─────────────────────────────────────────────

/// Trạng thái đồng bộ – dùng chung cho mọi bản ghi (tiêm, thuốc, dịch tễ).
enum SyncStatus { pending, synced }

/// Mức độ tiêm chủng của trẻ.
enum ChildVaccinationStatus { complete, dueSoon, late }

/// Mức độ phản ứng sau tiêm – theo phân loại y tế chuẩn.
enum ReactionSeverity {
  none,   // Không có phản ứng
  mild,   // Nhẹ: sốt < 38.5°C, sưng đỏ < 2cm
  moderate, // Trung bình: sốt 38.5–39.5°C, quấy khóc kéo dài
  severe, // Nặng: sốt > 39.5°C, co giật, khó thở → chuyển viện
}

/// Mức độ khẩn cấp của ca bệnh nghi nhiễm.
enum DiseaseUrgency { routine, elevated, emergency }

// Backward-compat alias – tránh sửa toàn bộ các file tham chiếu cũ ngay.
typedef VaccinationSyncStatus = SyncStatus;

// ─────────────────────────────────────────────
// Danh mục địa bàn cố định (tránh nhập tay)
// ─────────────────────────────────────────────

/// Danh sách xã trực thuộc huyện Sa Pa.
const kCommuneList = <String>[
  'Tả Phìn',
  'Tả Van',
  'Lao Chải',
  'Hầu Thào',
  'San Sả Hồ',
  'Bản Hồ',
];

/// Mapping thôn/bản theo từng xã – dùng cho DropdownButtonFormField.
const kVillagesByCommune = <String, List<String>>{
  'Tả Phìn': ['Bản Nậm Lùng', 'Bản Tả Phìn', 'Bản Sả Séng', 'Bản Giàng Tra'],
  'Tả Van': ['Bản Séo Mý Tỷ', 'Bản Tả Van', 'Bản Lý Lao Chải', 'Bản Giàng Tả Chải'],
  'Lao Chải': ['Bản Lao Chải', 'Bản Sin Chải', 'Bản Hang Đá', 'Bản Dền Thàng'],
  'Hầu Thào': ['Bản Hầu Thào', 'Bản Má Tra', 'Bản Lý', 'Bản Phùng'],
  'San Sả Hồ': ['Bản Sín Chải', 'Bản San Sả Hồ', 'Bản Cát Cát', 'Bản Ý Lìn Hồ'],
  'Bản Hồ': ['Bản Bản Hồ', 'Bản Nậm Tống', 'Bản Dền Thàng', 'Bản Nậm Sài'],
};

// ─────────────────────────────────────────────
// Thông tin người dùng đăng nhập
// ─────────────────────────────────────────────

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.assignedCommune,
  });

  final String id;
  final String fullName;
  final String role; // 'y_si' | 'admin'
  final String assignedCommune; // Xã phụ trách
}

/// Danh sách y sĩ phụ trách theo từng xã – quy trách nhiệm cán bộ.
const kHealthWorkers = <String, List<String>>{
  'Tả Phìn': ['Y sĩ Lê Thu', 'Y sĩ Nguyễn Mai'],
  'Tả Van': ['Y sĩ Trần Nam', 'Y sĩ Hoàng Lan'],
  'Lao Chải': ['Y sĩ Hà Linh', 'Y sĩ Đỗ Quang'],
  'Hầu Thào': ['Y sĩ Lê Thu', 'Y sĩ Trần Nam'],
  'San Sả Hồ': ['Y sĩ Hà Linh', 'Y sĩ Nguyễn Mai'],
  'Bản Hồ': ['Y sĩ Hà Linh', 'Y sĩ Đỗ Quang'],
};

// ─────────────────────────────────────────────
// Model: Bản ghi tiêm chủng
// ─────────────────────────────────────────────

class VaccinationRecord {
  const VaccinationRecord({
    required this.id,
    required this.childId,
    required this.vaccineId,
    required this.vaccineName,
    required this.doseNumber,
    required this.lotNumber,
    required this.administeredBy,
    required this.administeredAt,
    required this.syncStatus,
    this.reactions,
    this.reactionSeverity = ReactionSeverity.none,
    this.storageTemperature,
  });

  final String id;
  final String childId;
  final String vaccineId;
  final String vaccineName;
  final int doseNumber;
  final String lotNumber;
  final String administeredBy;
  final String? reactions;
  final ReactionSeverity reactionSeverity;
  /// Nhiệt độ bảo quản vaccine (°C) – null nếu chưa kiểm tra.
  final double? storageTemperature;
  final DateTime administeredAt;
  final SyncStatus syncStatus;

  /// Kiểm tra nhiệt độ bảo quản nằm trong chuỗi lạnh 2–8°C.
  bool get isColdChainValid =>
      storageTemperature != null &&
      storageTemperature! >= 2.0 &&
      storageTemperature! <= 8.0;

  /// Cảnh báo khi nhiệt độ bảo quản nằm ngoài ngưỡng.
  String? get coldChainWarning {
    if (storageTemperature == null) return 'Chưa ghi nhận nhiệt độ bảo quản';
    if (storageTemperature! < 2.0) return '⚠ Vaccine có thể bị đóng băng (${storageTemperature!.toStringAsFixed(1)}°C)';
    if (storageTemperature! > 8.0) return '⚠ Vaccine có thể mất hiệu lực (${storageTemperature!.toStringAsFixed(1)}°C)';
    return null;
  }

  VaccinationRecord copyWith({SyncStatus? syncStatus}) {
    return VaccinationRecord(
      id: id,
      childId: childId,
      vaccineId: vaccineId,
      vaccineName: vaccineName,
      doseNumber: doseNumber,
      lotNumber: lotNumber,
      administeredBy: administeredBy,
      reactions: reactions,
      reactionSeverity: reactionSeverity,
      storageTemperature: storageTemperature,
      administeredAt: administeredAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

// ─────────────────────────────────────────────
// Model: Bản ghi cho uống thuốc
// ─────────────────────────────────────────────

class MedicationRecord {
  const MedicationRecord({
    required this.id,
    required this.childId,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.administeredBy,
    required this.administeredAt,
    required this.syncStatus,
    this.notes,
  });

  final String id;
  final String childId;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String administeredBy;
  final DateTime administeredAt;
  final SyncStatus syncStatus;
  final String? notes;

  MedicationRecord copyWith({SyncStatus? syncStatus}) {
    return MedicationRecord(
      id: id,
      childId: childId,
      medicationId: medicationId,
      medicationName: medicationName,
      dosage: dosage,
      administeredBy: administeredBy,
      administeredAt: administeredAt,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes,
    );
  }
}

// ─────────────────────────────────────────────
// Model: Hồ sơ trẻ em
// ─────────────────────────────────────────────

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.qrCode,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.motherName,
    required this.motherPhone,
    required this.village,
    required this.commune,
    required this.district,
    required this.status,
    required this.nextVaccine,
    required this.nextDue,
    required this.lateDays,
    required this.vaccinations,
    this.medications = const [],
  });

  final String id;
  final String qrCode;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String motherName;
  final String motherPhone;
  final String village;
  final String commune;
  final String district;
  final ChildVaccinationStatus status;
  final String nextVaccine;
  final DateTime nextDue;
  final int lateDays;
  final List<VaccinationRecord> vaccinations;
  final List<MedicationRecord> medications;

  ChildProfile copyWith({
    String? qrCode,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? motherName,
    String? motherPhone,
    String? village,
    String? commune,
    String? district,
    ChildVaccinationStatus? status,
    String? nextVaccine,
    DateTime? nextDue,
    int? lateDays,
    List<VaccinationRecord>? vaccinations,
    List<MedicationRecord>? medications,
  }) {
    return ChildProfile(
      id: id,
      qrCode: qrCode ?? this.qrCode,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      motherName: motherName ?? this.motherName,
      motherPhone: motherPhone ?? this.motherPhone,
      village: village ?? this.village,
      commune: commune ?? this.commune,
      district: district ?? this.district,
      status: status ?? this.status,
      nextVaccine: nextVaccine ?? this.nextVaccine,
      nextDue: nextDue ?? this.nextDue,
      lateDays: lateDays ?? this.lateDays,
      vaccinations: vaccinations ?? this.vaccinations,
      medications: medications ?? this.medications,
    );
  }
}

// ─────────────────────────────────────────────
// Model: Lịch tiêm vaccine chuẩn
// ─────────────────────────────────────────────

class VaccineSchedule {
  const VaccineSchedule({
    required this.id,
    required this.vaccineName,
    required this.doseNumber,
    required this.ageMonths,
    required this.toleranceDays,
    required this.description,
  });

  final String id;
  final String vaccineName;
  final int doseNumber;
  final int ageMonths;
  final int toleranceDays;
  final String description;

  String get displayName => '$vaccineName - Mũi $doseNumber';
}

// ─────────────────────────────────────────────
// Model: Lịch cho uống thuốc
// ─────────────────────────────────────────────

class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.medicationName,
    required this.recommendedAge,
    required this.defaultDosage,
    required this.description,
  });

  final String id;
  final String medicationName;
  final String recommendedAge;
  final String defaultDosage;
  final String description;

  String get displayName => '$medicationName ($defaultDosage)';
}

// ─────────────────────────────────────────────
// Model: Tỷ lệ phủ vaccine theo xã
// ─────────────────────────────────────────────

class CommuneCoverage {
  const CommuneCoverage({
    required this.name,
    required this.total,
    required this.fully,
    required this.coverage,
    required this.bcg,
    required this.dpt1,
    required this.dpt2,
    required this.dpt3,
  });

  final String name;
  final int total;
  final int fully;
  final double coverage;
  final int bcg;
  final int dpt1;
  final int dpt2;
  final int dpt3;

  int get missing => total - fully;
}

// ─────────────────────────────────────────────
// Model: Báo cáo Dịch tễ – Ca bệnh nghi ngờ
// ─────────────────────────────────────────────

/// Danh mục bệnh truyền nhiễm cần giám sát.
class DiseaseType {
  const DiseaseType({
    required this.id,
    required this.name,
    required this.symptoms,
    required this.incubationDays,
  });

  final String id;
  final String name;
  final List<String> symptoms;
  final String incubationDays; // VD: '7–21 ngày'
}

/// Phiếu báo cáo ca bệnh nghi nhiễm – y sĩ khai báo khi đi bản.
class DiseaseReport {
  const DiseaseReport({
    required this.id,
    required this.diseaseTypeId,
    required this.diseaseName,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.village,
    required this.commune,
    required this.symptoms,
    required this.onsetDate,
    required this.reportedBy,
    required this.reportedAt,
    required this.urgency,
    required this.syncStatus,
    this.notes,
    this.relatedChildId,
  });

  final String id;
  final String diseaseTypeId;
  final String diseaseName;
  final String patientName;
  final int patientAge; // tuổi (tháng nếu < 5 tuổi, năm nếu >= 5)
  final String patientGender;
  final String village;
  final String commune;
  final List<String> symptoms;
  final DateTime onsetDate;   // Ngày khởi phát triệu chứng
  final String reportedBy;
  final DateTime reportedAt;
  final DiseaseUrgency urgency;
  final SyncStatus syncStatus;
  final String? notes;
  /// Liên kết với trẻ trong sổ theo dõi (nếu bệnh nhân là trẻ em).
  final String? relatedChildId;

  DiseaseReport copyWith({SyncStatus? syncStatus}) {
    return DiseaseReport(
      id: id,
      diseaseTypeId: diseaseTypeId,
      diseaseName: diseaseName,
      patientName: patientName,
      patientAge: patientAge,
      patientGender: patientGender,
      village: village,
      commune: commune,
      symptoms: symptoms,
      onsetDate: onsetDate,
      reportedBy: reportedBy,
      reportedAt: reportedAt,
      urgency: urgency,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes,
      relatedChildId: relatedChildId,
    );
  }
}

// ─────────────────────────────────────────────
// Hàm tiện ích: Sinh mã QR có cấu trúc
// ─────────────────────────────────────────────

/// Sinh mã định danh QR Code chuẩn y tế:
/// Format: `{mã_huyện}-{mã_xã_viết_tắt}-{năm_sinh_2_số}-{counter_4_số}`
/// VD: `SP-TPH-24-0001`
String generateStructuredQrCode({
  required String district,
  required String commune,
  required DateTime dateOfBirth,
  required int counter,
}) {
  // Mã huyện: 2 ký tự viết tắt
  final districtCode = switch (district.toLowerCase()) {
    'sa pa' => 'SP',
    'bát xát' => 'BX',
    'bắc hà' => 'BH',
    _ => district.substring(0, 2).toUpperCase(),
  };
  // Mã xã: 3 ký tự đầu viết tắt (bỏ dấu đơn giản)
  final communeWords = commune.split(' ');
  final communeCode = communeWords.length >= 2
      ? '${communeWords[0][0]}${communeWords[1][0]}${communeWords.last.isEmpty ? '' : communeWords.last[0]}'.toUpperCase()
      : commune.substring(0, 3).toUpperCase();
  // Năm sinh 2 số
  final yearCode = (dateOfBirth.year % 100).toString().padLeft(2, '0');
  // Counter 4 số
  final counterCode = counter.toString().padLeft(4, '0');
  return '$districtCode-$communeCode-$yearCode-$counterCode';
}
