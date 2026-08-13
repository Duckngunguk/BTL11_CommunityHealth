import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/models.dart';

class FirebaseSyncService {
  FirebaseSyncService._internal();
  static final FirebaseSyncService instance = FirebaseSyncService._internal();

  bool _isInitialized = false;
  bool _initializationAttempted = false;
  String? _lastError;

  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  // Initialize Firebase core and catch failures gracefully to avoid startup crash
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_initializationAttempted) return false;
    _initializationAttempted = true;
    try {
      debugPrint('Attempting to initialize Firebase Core...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      _lastError = null;
      debugPrint('Firebase Core successfully initialized.');
      return true;
    } catch (e) {
      _isInitialized = false;
      // Allow a later refresh to retry after a temporary network/config error.
      _initializationAttempted = false;
      _lastError = e.toString();
      debugPrint('Firebase unavailable; data remains pending: $e');
      return false;
    }
  }

  /// Downloads a complete application snapshot directly from Firestore.
  /// `null` represents a failed read; empty collections remain valid data.
  Future<FirebaseCloudSnapshot?> fetchCloudSnapshot() async {
    if (!await initialize()) return null;

    try {
      const server = GetOptions(source: Source.server);
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get(server);
      final childrenSnapshot =
          await firestore.collection('children').get(server);
      final vaccinationsSnapshot =
          await firestore.collection('vaccinations').get(server);
      final medicationsSnapshot =
          await firestore.collection('medications').get(server);
      final reportsSnapshot =
          await firestore.collection('disease_reports').get(server);
      final logsSnapshot = await firestore.collection('audit_logs').get(server);
      final vaccinesSnapshot =
          await firestore.collection('vaccine_schedules').get(server);
      final medicationSchedulesSnapshot =
          await firestore.collection('medication_schedules').get(server);

      final vaccinations = vaccinationsSnapshot.docs
          .map((doc) => VaccinationRecord.fromMap(doc.data()))
          .toList();
      final medications = medicationsSnapshot.docs
          .map((doc) => MedicationRecord.fromMap(doc.data()))
          .toList();
      final children = childrenSnapshot.docs.map((doc) {
        final data = doc.data();
        final childId = (data['id'] ?? doc.id).toString();
        return ChildProfile.fromMap(
          {...data, 'id': childId},
          vaccinations: vaccinations
              .where((record) => record.childId == childId)
              .toList(),
          medications:
              medications.where((record) => record.childId == childId).toList(),
        );
      }).toList();

      _lastError = null;
      return FirebaseCloudSnapshot(
        users: usersSnapshot.docs
            .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList(),
        children: children,
        diseaseReports: reportsSnapshot.docs
            .map((doc) => DiseaseReport.fromMap(doc.data()))
            .toList(),
        auditLogs: logsSnapshot.docs
            .map((doc) => SystemAuditLog.fromMap(doc.data()))
            .toList(),
        vaccineSchedules: vaccinesSnapshot.docs
            .map((doc) => VaccineSchedule.fromMap(doc.data()))
            .toList(),
        medicationSchedules: medicationSchedulesSnapshot.docs
            .map((doc) => MedicationSchedule.fromMap(doc.data()))
            .toList(),
      );
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[Firestore Snapshot Fetch Error]: $e');
      return null;
    }
  }

  // Upload a vaccination record to Firestore
  Future<bool> syncVaccinationRecord(VaccinationRecord record) async {
    await initialize();

    if (!_isInitialized) return false;

    try {
      debugPrint(
          '🔥 [Firestore Sync] Syncing Vaccination Record: ${record.id}');
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(record.id)
          .set({
        'id': record.id,
        'childId': record.childId,
        'vaccineId': record.vaccineId,
        'vaccineName': record.vaccineName,
        'doseNumber': record.doseNumber,
        'lotNumber': record.lotNumber,
        'administeredBy': record.administeredBy,
        'reactions': record.reactions,
        'administeredAt': record.administeredAt.toIso8601String(),
        'syncStatus': 'synced',
      });
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync Error]: $e');
      return false;
    }
  }

  // Upload a disease report to Firestore
  Future<bool> syncDiseaseReport(DiseaseReport report) async {
    await initialize();

    if (!_isInitialized) return false;

    try {
      debugPrint('🔥 [Firestore Sync] Syncing Disease Report: ${report.id}');
      await FirebaseFirestore.instance
          .collection('disease_reports')
          .doc(report.id)
          .set({
        'id': report.id,
        'childId': report.childId,
        'patientName': report.patientName,
        'diseaseType': report.diseaseType,
        'village': report.village,
        'commune': report.commune,
        'district': report.district,
        'reportedAt': report.reportedAt.toIso8601String(),
        'reportedBy': report.reportedBy,
        'symptoms': report.symptoms,
        'status': report.status,
        'severity': report.severity.name,
        'notes': report.notes,
        'syncStatus': 'synced',
      });
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync Error]: $e');
      return false;
    }
  }

  Future<bool> syncMedicationRecord(MedicationRecord record) async {
    await initialize();
    if (!_isInitialized) return false;

    try {
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(record.id)
          .set({...record.toMap(), 'syncStatus': 'synced'});
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Medication Sync Error]: $e');
      return false;
    }
  }

  /// Creates or updates the child profile stored in Firestore.
  /// Vaccination and medication records remain in their own collections.
  Future<bool> syncChild(ChildProfile child) async {
    await initialize();
    if (!_isInitialized) return false;

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .set(child.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Child Sync Error]: $e');
      return false;
    }
  }

  /// Deletes a child and all records belonging to that child atomically.
  Future<bool> deleteChild(String childId) async {
    await initialize();
    if (!_isInitialized) return false;

    try {
      final firestore = FirebaseFirestore.instance;
      final vaccinations = await firestore
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .get();
      final medications = await firestore
          .collection('medications')
          .where('childId', isEqualTo: childId)
          .get();
      final batch = firestore.batch();
      batch.delete(firestore.collection('children').doc(childId));
      for (final document in vaccinations.docs) {
        batch.delete(document.reference);
      }
      for (final document in medications.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Child Delete Error]: $e');
      return false;
    }
  }

  // Upload all vaccination records in a SyncBatch using Firestore WriteBatch for atomicity
  Future<bool> syncBatchUpload(
      SyncBatch batch, List<VaccinationRecord> records) async {
    await initialize();

    if (!_isInitialized) return false;

    try {
      debugPrint('🔥 [Firestore Batch Sync] Syncing Batch: ${batch.id}');
      final firestore = FirebaseFirestore.instance;
      final firestoreBatch = firestore.batch();

      // 1. Write the batch metadata document
      final batchDoc = firestore.collection('sync_batches').doc(batch.id);
      firestoreBatch.set(batchDoc, batch.toMap());

      // 2. Write each vaccination record document
      for (var record in records) {
        final recordDoc = firestore.collection('vaccinations').doc(record.id);
        firestoreBatch.set(recordDoc, {
          'id': record.id,
          'childId': record.childId,
          'vaccineId': record.vaccineId,
          'vaccineName': record.vaccineName,
          'doseNumber': record.doseNumber,
          'lotNumber': record.lotNumber,
          'administeredBy': record.administeredBy,
          'reactions': record.reactions,
          'administeredAt': record.administeredAt.toIso8601String(),
          'syncStatus': 'synced',
        });
      }

      // Commit the batch transaction
      await firestoreBatch.commit();
      debugPrint(
          '🔥 [Firestore Batch Sync] Batch ${batch.id} committed successfully.');
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Batch Sync Error]: $e');
      return false;
    }
  }

  // Upload/Sync a user profile to Firestore
  Future<bool> syncUser(UserModel user) async {
    await initialize();

    if (!_isInitialized) return false;

    try {
      debugPrint('🔥 [Firestore Sync] Syncing User: ${user.username}');
      final cloudData = user.toMap()..remove('token');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(cloudData);
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync User Error]: $e');
      return false;
    }
  }

  // Sync a single system audit log to Firestore
  Future<bool> syncAuditLog(SystemAuditLog log) async {
    await initialize();

    if (!_isInitialized) return false;

    try {
      debugPrint('🔥 [Firestore Sync] Syncing Audit Log: ${log.id}');
      await FirebaseFirestore.instance
          .collection('audit_logs')
          .doc(log.id)
          .set(log.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync Log Error]: $e');
      return false;
    }
  }

  // Fetch all registered users from Firestore
  Future<List<UserModel>> fetchUsers() async {
    await initialize();
    if (!_isInitialized) return [];

    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Users...');
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Users Error]: $e');
      return [];
    }
  }

  // Fetch all children profiles from Firestore along with their vaccinations and medications
  Future<List<ChildProfile>> fetchChildren() async {
    await initialize();
    if (!_isInitialized) return [];

    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Children & Records...');
      final snapshot =
          await FirebaseFirestore.instance.collection('children').get();
      final vacsSnapshot =
          await FirebaseFirestore.instance.collection('vaccinations').get();
      final medsSnapshot =
          await FirebaseFirestore.instance.collection('medications').get();

      final allVacs = vacsSnapshot.docs
          .map((doc) => VaccinationRecord.fromMap(doc.data()))
          .toList();
      final allMeds = medsSnapshot.docs
          .map((doc) => MedicationRecord.fromMap(doc.data()))
          .toList();

      final List<ChildProfile> list = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final childId = data['id'] as String;

        final childVacs = allVacs.where((v) => v.childId == childId).toList();
        final childMeds = allMeds.where((m) => m.childId == childId).toList();

        list.add(ChildProfile.fromMap(data,
            vaccinations: childVacs, medications: childMeds));
      }
      return list;
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Children Error]: $e');
      return [];
    }
  }

  // Fetch all disease reports from Firestore
  Future<List<DiseaseReport>> fetchDiseaseReports() async {
    await initialize();
    if (!_isInitialized) return [];

    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Disease Reports...');
      final snapshot =
          await FirebaseFirestore.instance.collection('disease_reports').get();
      return snapshot.docs
          .map((doc) => DiseaseReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Disease Reports Error]: $e');
      return [];
    }
  }

  // Fetch all system audit logs from Firestore
  Future<List<SystemAuditLog>> fetchAuditLogs() async {
    await initialize();
    if (!_isInitialized) return [];

    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Audit Logs...');
      final snapshot =
          await FirebaseFirestore.instance.collection('audit_logs').get();
      return snapshot.docs
          .map((doc) => SystemAuditLog.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Logs Error]: $e');
      return [];
    }
  }

  // Delete a user from Firestore
  Future<bool> deleteUser(String userId) async {
    await initialize();
    if (!_isInitialized) return false;

    try {
      debugPrint('🔥 [Firestore Delete] Deleting User: $userId');
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Delete User Error]: $e');
      return false;
    }
  }

  // Sync vaccine catalog to Firestore
  Future<bool> syncVaccineSchedule(VaccineSchedule schedule) async {
    await initialize();
    if (!_isInitialized) return false;
    try {
      debugPrint(
          '🔥 [Firestore Sync] Syncing Vaccine Schedule: ${schedule.id}');
      await FirebaseFirestore.instance
          .collection('vaccine_schedules')
          .doc(schedule.id)
          .set(schedule.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync Vaccine Error]: $e');
      return false;
    }
  }

  // Sync medication catalog to Firestore
  Future<bool> syncMedicationSchedule(MedicationSchedule schedule) async {
    await initialize();
    if (!_isInitialized) return false;
    try {
      debugPrint(
          '🔥 [Firestore Sync] Syncing Medication Schedule: ${schedule.id}');
      await FirebaseFirestore.instance
          .collection('medication_schedules')
          .doc(schedule.id)
          .set(schedule.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync Medication Error]: $e');
      return false;
    }
  }

  // Fetch vaccine catalogs from Firestore
  Future<List<VaccineSchedule>> fetchVaccineSchedules() async {
    await initialize();
    if (!_isInitialized) return [];
    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Vaccine Schedules...');
      final snapshot = await FirebaseFirestore.instance
          .collection('vaccine_schedules')
          .get();
      return snapshot.docs
          .map((doc) => VaccineSchedule.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Vaccines Error]: $e');
      return [];
    }
  }

  // Fetch medication catalogs from Firestore
  Future<List<MedicationSchedule>> fetchMedicationSchedules() async {
    await initialize();
    if (!_isInitialized) return [];
    try {
      debugPrint('🔥 [Firestore Fetch] Fetching Medication Schedules...');
      final snapshot = await FirebaseFirestore.instance
          .collection('medication_schedules')
          .get();
      return snapshot.docs
          .map((doc) => MedicationSchedule.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Medications Error]: $e');
      return [];
    }
  }
}

class FirebaseCloudSnapshot {
  const FirebaseCloudSnapshot({
    required this.users,
    required this.children,
    required this.diseaseReports,
    required this.auditLogs,
    required this.vaccineSchedules,
    required this.medicationSchedules,
  });

  final List<UserModel> users;
  final List<ChildProfile> children;
  final List<DiseaseReport> diseaseReports;
  final List<SystemAuditLog> auditLogs;
  final List<VaccineSchedule> vaccineSchedules;
  final List<MedicationSchedule> medicationSchedules;

  bool get hasAnyData =>
      users.isNotEmpty ||
      children.isNotEmpty ||
      diseaseReports.isNotEmpty ||
      auditLogs.isNotEmpty ||
      vaccineSchedules.isNotEmpty ||
      medicationSchedules.isNotEmpty;
}
