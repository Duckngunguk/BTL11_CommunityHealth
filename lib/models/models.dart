enum VaccinationSyncStatus { pending, synced }

enum ChildVaccinationStatus { complete, dueSoon, late }

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
}


