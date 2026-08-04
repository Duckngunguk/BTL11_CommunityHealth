
enum VaccinationSyncStatus { pending, synced }

enum ChildVaccinationStatus { complete, dueSoon, late }

enum UserRole { healthWorker, parent, admin }

enum UserAccountStatus { active, pendingApproval, locked }

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.token,
    this.assignedCommune,
    this.password,
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final UserAccountStatus status;
  final DateTime createdAt;
  final String? token;
  final String? assignedCommune;
  final String? password;

  bool get isActive => status == UserAccountStatus.active;
  bool get isPending => status == UserAccountStatus.pendingApproval;

  UserModel copyWith({
    UserAccountStatus? status,
    String? token,
    String? assignedCommune,
    String? password,
  }) {
    return UserModel(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status ?? this.status,
      createdAt: createdAt,
      token: token ?? this.token,
      assignedCommune: assignedCommune ?? this.assignedCommune,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'token': token,
      'assignedCommune': assignedCommune,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      status: UserAccountStatus.values.firstWhere((e) => e.name == map['status']),
      createdAt: DateTime.parse(map['createdAt'] as String),
      token: map['token'] as String?,
      assignedCommune: map['assignedCommune'] as String?,
      password: map['password'] as String?,
    );
  }
}

class SystemAuditLog {
  const SystemAuditLog({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.userRole,
    required this.timestamp,
    required this.details,
  });

  final String id;
  final String action;
  final String performedBy;
  final String userRole;
  final DateTime timestamp;
  final String details;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'userRole': userRole,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  factory SystemAuditLog.fromMap(Map<String, dynamic> map) {
    return SystemAuditLog(
      id: map['id'] as String,
      action: map['action'] as String,
      performedBy: map['performedBy'] as String,
      userRole: map['userRole'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      details: map['details'] as String,
    );
  }
}

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
  });

  final String id;
  final String childId;
  final String vaccineId;
  final String vaccineName;
  final int doseNumber;
  final String lotNumber;
  final String administeredBy;
  final String? reactions;
  final DateTime administeredAt;
  final VaccinationSyncStatus syncStatus;

  VaccinationRecord copyWith({VaccinationSyncStatus? syncStatus}) {
    return VaccinationRecord(
      id: id,
      childId: childId,
      vaccineId: vaccineId,
      vaccineName: vaccineName,
      doseNumber: doseNumber,
      lotNumber: lotNumber,
      administeredBy: administeredBy,
      reactions: reactions,
      administeredAt: administeredAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'vaccineId': vaccineId,
      'vaccineName': vaccineName,
      'doseNumber': doseNumber,
      'lotNumber': lotNumber,
      'administeredBy': administeredBy,
      'reactions': reactions,
      'administeredAt': administeredAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'] as String,
      childId: map['childId'] as String,
      vaccineId: map['vaccineId'] as String,
      vaccineName: map['vaccineName'] as String,
      doseNumber: map['doseNumber'] as int,
      lotNumber: map['lotNumber'] as String,
      administeredBy: map['administeredBy'] as String,
      reactions: map['reactions'] as String?,
      administeredAt: DateTime.parse(map['administeredAt'] as String),
      syncStatus: VaccinationSyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
    );
  }
}

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
  final VaccinationSyncStatus syncStatus;
  final String? notes;

  MedicationRecord copyWith({VaccinationSyncStatus? syncStatus}) {
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'administeredBy': administeredBy,
      'administeredAt': administeredAt.toIso8601String(),
      'syncStatus': syncStatus.name,
      'notes': notes,
    };
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'] as String,
      childId: map['childId'] as String,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      dosage: map['dosage'] as String,
      administeredBy: map['administeredBy'] as String,
      administeredAt: DateTime.parse(map['administeredAt'] as String),
      syncStatus: VaccinationSyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
      notes: map['notes'] as String?,
    );
  }
}

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
    this.lastSyncAt,
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
  final DateTime? lastSyncAt;

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
    DateTime? lastSyncAt,
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
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qrCode': qrCode,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'motherName': motherName,
      'motherPhone': motherPhone,
      'village': village,
      'commune': commune,
      'district': district,
      'status': status.name,
      'nextVaccine': nextVaccine,
      'nextDue': nextDue.toIso8601String(),
      'lateDays': lateDays,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(
    Map<String, dynamic> map, {
    List<VaccinationRecord> vaccinations = const [],
    List<MedicationRecord> medications = const [],
  }) {
    return ChildProfile(
      id: map['id'] as String,
      qrCode: map['qrCode'] as String,
      fullName: map['fullName'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      gender: map['gender'] as String,
      motherName: map['motherName'] as String,
      motherPhone: map['motherPhone'] as String,
      village: map['village'] as String,
      commune: map['commune'] as String,
      district: map['district'] as String,
      status: ChildVaccinationStatus.values.firstWhere((e) => e.name == map['status']),
      nextVaccine: map['nextVaccine'] as String,
      nextDue: DateTime.parse(map['nextDue'] as String),
      lateDays: map['lateDays'] as int,
      vaccinations: vaccinations,
      medications: medications,
      lastSyncAt: map['lastSyncAt'] != null ? DateTime.parse(map['lastSyncAt'] as String) : null,
    );
  }
}

enum SyncBatchStatus { uploaded, processed, error }

class SyncBatch {
  const SyncBatch({
    required this.id,
    required this.deviceId,
    required this.healthworkerId,
    required this.vaccinationIds,
    required this.status,
    required this.uploadedAt,
    this.errorMessage,
  });

  final String id;
  final String deviceId;
  final String healthworkerId;
  final List<String> vaccinationIds;
  final SyncBatchStatus status;
  final DateTime uploadedAt;
  final String? errorMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'healthworkerId': healthworkerId,
      'vaccinationIds': vaccinationIds.join(','),
      'status': status.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory SyncBatch.fromMap(Map<String, dynamic> map) {
    final vIdsRaw = map['vaccinationIds'] as String;
    final List<String> vIds = vIdsRaw.isEmpty ? [] : vIdsRaw.split(',');
    return SyncBatch(
      id: map['id'] as String,
      deviceId: map['deviceId'] as String,
      healthworkerId: map['healthworkerId'] as String,
      vaccinationIds: vIds,
      status: SyncBatchStatus.values.firstWhere((e) => e.name == map['status']),
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      errorMessage: map['errorMessage'] as String?,
    );
  }
}

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

enum DiseaseSeverity { mild, moderate, severe }

class DiseaseReport {
  const DiseaseReport({
    required this.id,
    required this.patientName,
    required this.diseaseType,
    required this.village,
    required this.commune,
    required this.district,
    required this.reportedAt,
    required this.reportedBy,
    required this.symptoms,
    required this.syncStatus,
    this.childId,
    this.status = 'Nghi ngờ',
    this.severity = DiseaseSeverity.moderate,
    this.notes,
  });

  final String id;
  final String? childId;
  final String patientName;
  final String diseaseType;
  final String village;
  final String commune;
  final String district;
  final DateTime reportedAt;
  final String reportedBy;
  final String symptoms;
  final VaccinationSyncStatus syncStatus;
  final String status;
  final DiseaseSeverity severity;
  final String? notes;

  DiseaseReport copyWith({
    VaccinationSyncStatus? syncStatus,
    String? status,
  }) {
    return DiseaseReport(
      id: id,
      childId: childId,
      patientName: patientName,
      diseaseType: diseaseType,
      village: village,
      commune: commune,
      district: district,
      reportedAt: reportedAt,
      reportedBy: reportedBy,
      symptoms: symptoms,
      syncStatus: syncStatus ?? this.syncStatus,
      status: status ?? this.status,
      severity: severity,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'patientName': patientName,
      'diseaseType': diseaseType,
      'village': village,
      'commune': commune,
      'district': district,
      'reportedAt': reportedAt.toIso8601String(),
      'reportedBy': reportedBy,
      'symptoms': symptoms,
      'syncStatus': syncStatus.name,
      'status': status,
      'severity': severity.name,
      'notes': notes,
    };
  }

  factory DiseaseReport.fromMap(Map<String, dynamic> map) {
    return DiseaseReport(
      id: map['id'] as String,
      childId: map['childId'] as String?,
      patientName: map['patientName'] as String,
      diseaseType: map['diseaseType'] as String,
      village: map['village'] as String,
      commune: map['commune'] as String,
      district: map['district'] as String,
      reportedAt: DateTime.parse(map['reportedAt'] as String),
      reportedBy: map['reportedBy'] as String,
      symptoms: map['symptoms'] as String,
      syncStatus: VaccinationSyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
      status: map['status'] as String,
      severity: DiseaseSeverity.values.firstWhere((e) => e.name == map['severity']),
      notes: map['notes'] as String?,
    );
  }
}

const Map<String, List<String>> kVillagesByCommune = {
  'Tả Phìn': ['Bản Nậm Lùng', 'Bản Tả Phìn 1', 'Bản Tả Phìn 2', 'Bản Sả Séng', 'Bản Lếch'],
  'Hầu Thào': ['Bản Hầu Thào', 'Bản Hang Đá', 'Bản Lý Lao Chải'],
  'San Sả Hồ': ['Bản Sín Chải', 'Bản Cát Cát', 'Bản Ý Lình Hồ'],
  'Tả Van': ['Bản Séo Mý Tỷ', 'Bản Tả Van Giáy', 'Bản Tả Van Mông'],
  'Lao Chải': ['Bản Lao Chải', 'Bản Cát Cát Mông', 'Bản Ý Lình Hồ 2'],
  'Bản Hồ': ['Bản Bản Hồ', 'Bản Hồ', 'Bản Séo Trung Hồ', 'Bản La Ve'],
};
