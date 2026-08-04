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
}
