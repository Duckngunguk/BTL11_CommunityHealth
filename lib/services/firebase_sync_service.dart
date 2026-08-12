import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseSyncService {
  FirebaseSyncService._internal();
  static final FirebaseSyncService instance = FirebaseSyncService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Initialize Firebase core and catch failures gracefully to avoid startup crash
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      debugPrint('Attempting to initialize Firebase Core...');
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('✅ Firebase Core successfully initialized.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('⚠️ Firebase Core failed to initialize (google-services.json likely missing).');
      debugPrint('Sync engine will operate in SIMULATED Mode. Error: $e');
    }
  }

  // Upload a vaccination record to Firestore
  Future<bool> syncVaccinationRecord(VaccinationRecord record) async {
    await initialize();

    if (!_isInitialized) {
      // Simulated cloud sync delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('☁️ [Simulated Cloud Sync] Synced Vaccination Record: ${record.id}');
      return true;
    }

    try {
      debugPrint('🔥 [Firestore Sync] Syncing Vaccination Record: ${record.id}');
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

    if (!_isInitialized) {
      // Simulated cloud sync delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('☁️ [Simulated Cloud Sync] Synced Disease Report: ${report.id}');
      return true;
    }

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

  // Upload all vaccination records in a SyncBatch using Firestore WriteBatch for atomicity
  Future<bool> syncBatchUpload(SyncBatch batch, List<VaccinationRecord> records) async {
    await initialize();

    if (!_isInitialized) {
      // Simulated cloud sync delay
      await Future<void>.delayed(const Duration(milliseconds: 600));
      debugPrint('☁️ [Simulated Cloud Batch Sync] Uploaded Batch: ${batch.id} with ${records.length} records');
      return true;
    }

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
      debugPrint('🔥 [Firestore Batch Sync] Batch ${batch.id} committed successfully.');
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Batch Sync Error]: $e');
      return false;
    }
  }

  // Upload/Sync a user profile to Firestore
  Future<bool> syncUser(UserModel user) async {
    await initialize();

    if (!_isInitialized) {
      // Simulated cloud sync delay
      await Future<void>.delayed(const Duration(milliseconds: 300));
      debugPrint('☁️ [Simulated Cloud Sync] Synced User: ${user.username}');
      return true;
    }

    try {
      debugPrint('🔥 [Firestore Sync] Syncing User: ${user.username}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(user.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore Sync User Error]: $e');
      return false;
    }
  }

  // Sync a single system audit log to Firestore
  Future<bool> syncAuditLog(SystemAuditLog log) async {
    await initialize();

    if (!_isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      debugPrint('☁️ [Simulated Cloud Sync] Synced Audit Log: ${log.id}');
      return true;
    }

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
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
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
      final snapshot = await FirebaseFirestore.instance.collection('children').get();
      final vacsSnapshot = await FirebaseFirestore.instance.collection('vaccinations').get();
      final medsSnapshot = await FirebaseFirestore.instance.collection('medications').get();

      final allVacs = vacsSnapshot.docs.map((doc) => VaccinationRecord.fromMap(doc.data())).toList();
      final allMeds = medsSnapshot.docs.map((doc) => MedicationRecord.fromMap(doc.data())).toList();

      final List<ChildProfile> list = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final childId = data['id'] as String;

        final childVacs = allVacs.where((v) => v.childId == childId).toList();
        final childMeds = allMeds.where((m) => m.childId == childId).toList();

        list.add(ChildProfile.fromMap(data, vaccinations: childVacs, medications: childMeds));
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
      final snapshot = await FirebaseFirestore.instance.collection('disease_reports').get();
      return snapshot.docs.map((doc) => DiseaseReport.fromMap(doc.data())).toList();
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
      final snapshot = await FirebaseFirestore.instance.collection('audit_logs').get();
      return snapshot.docs.map((doc) => SystemAuditLog.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Logs Error]: $e');
      return [];
    }
  }

  // Delete a user from Firestore
  Future<bool> deleteUser(String userId) async {
    await initialize();
    if (!_isInitialized) return true;

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
    if (!_isInitialized) return true;
    try {
      debugPrint('🔥 [Firestore Sync] Syncing Vaccine Schedule: ${schedule.id}');
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
    if (!_isInitialized) return true;
    try {
      debugPrint('🔥 [Firestore Sync] Syncing Medication Schedule: ${schedule.id}');
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
      final snapshot = await FirebaseFirestore.instance.collection('vaccine_schedules').get();
      return snapshot.docs.map((doc) => VaccineSchedule.fromMap(doc.data())).toList();
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
      final snapshot = await FirebaseFirestore.instance.collection('medication_schedules').get();
      return snapshot.docs.map((doc) => MedicationSchedule.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ [Firestore Fetch Medications Error]: $e');
      return [];
    }
  }
}
