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

  ChildProfile copyWith({List<VaccinationRecord>? vaccinations}) {
    return ChildProfile(
      id: id,
      qrCode: qrCode,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      motherName: motherName,
      motherPhone: motherPhone,
      village: village,
      commune: commune,
      district: district,
      status: status,
      nextVaccine: nextVaccine,
      nextDue: nextDue,
      lateDays: lateDays,
      vaccinations: vaccinations ?? this.vaccinations,
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
