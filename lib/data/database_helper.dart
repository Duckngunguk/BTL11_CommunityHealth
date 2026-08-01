import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (kIsWeb) return null; // Web không hỗ trợ sqflite trực tiếp
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'community_health.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tạo bảng child
    await db.execute('''
      CREATE TABLE child (
        id TEXT PRIMARY KEY,
        qrCode TEXT,
        fullName TEXT,
        dateOfBirth TEXT,
        gender TEXT,
        motherName TEXT,
        motherPhone TEXT,
        village TEXT,
        commune TEXT,
        district TEXT,
        status TEXT,
        nextVaccine TEXT,
        nextDue TEXT,
        lateDays INTEGER
      )
    ''');

    // Tạo bảng vaccination_record
    await db.execute('''
      CREATE TABLE vaccination_record (
        id TEXT PRIMARY KEY,
        childId TEXT,
        vaccineId TEXT,
        vaccineName TEXT,
        doseNumber INTEGER,
        lotNumber TEXT,
        administeredBy TEXT,
        reactions TEXT,
        reactionSeverity TEXT,
        storageTemperature REAL,
        administeredAt TEXT,
        syncStatus TEXT
      )
    ''');

    // Tạo bảng medication_record
    await db.execute('''
      CREATE TABLE medication_record (
        id TEXT PRIMARY KEY,
        childId TEXT,
        medicationId TEXT,
        medicationName TEXT,
        dosage TEXT,
        administeredBy TEXT,
        administeredAt TEXT,
        syncStatus TEXT,
        notes TEXT
      )
    ''');

    // Tạo bảng disease_report
    await db.execute('''
      CREATE TABLE disease_report (
        id TEXT PRIMARY KEY,
        diseaseTypeId TEXT,
        diseaseName TEXT,
        patientName TEXT,
        patientAge INTEGER,
        patientGender TEXT,
        village TEXT,
        commune TEXT,
        symptoms TEXT,
        onsetDate TEXT,
        reportedBy TEXT,
        reportedAt TEXT,
        urgency TEXT,
        syncStatus TEXT,
        notes TEXT,
        relatedChildId TEXT
      )
    ''');
  }

  // ─────────────────────────────────────────────
  // CRUD cho Child
  // ─────────────────────────────────────────────

  Future<int> insertChild(ChildProfile child) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'child',
      _childToMap(child),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChildProfile>> getAllChildren() async {
    final db = await database;
    if (db == null) return [];

    final List<Map<String, dynamic>> maps = await db.query('child');
    final List<ChildProfile> list = [];

    for (final map in maps) {
      final childId = map['id'] as String;
      final vaccines = await getVaccinationsForChild(childId);
      final medications = await getMedicationsForChild(childId);
      list.add(_mapToChild(map, vaccines, medications));
    }
    return list;
  }

  Future<int> updateChild(ChildProfile child) async {
    final db = await database;
    if (db == null) return 0;
    return await db.update(
      'child',
      _childToMap(child),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<int> deleteChild(String childId) async {
    final db = await database;
    if (db == null) return 0;
    await db.delete('vaccination_record', where: 'childId = ?', whereArgs: [childId]);
    await db.delete('medication_record', where: 'childId = ?', whereArgs: [childId]);
    return await db.delete('child', where: 'id = ?', whereArgs: [childId]);
  }

  // ─────────────────────────────────────────────
  // CRUD cho VaccinationRecord
  // ─────────────────────────────────────────────

  Future<int> insertVaccination(VaccinationRecord record) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'vaccination_record',
      _vaccinationToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VaccinationRecord>> getVaccinationsForChild(String childId) async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'vaccination_record',
      where: 'childId = ?',
      whereArgs: [childId],
    );
    return maps.map(_mapToVaccination).toList();
  }

  Future<int> updateVaccinationSyncStatus(String recordId, String status) async {
    final db = await database;
    if (db == null) return 0;
    return await db.update(
      'vaccination_record',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // ─────────────────────────────────────────────
  // CRUD cho MedicationRecord
  // ─────────────────────────────────────────────

  Future<int> insertMedication(MedicationRecord record) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'medication_record',
      _medicationToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MedicationRecord>> getMedicationsForChild(String childId) async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'medication_record',
      where: 'childId = ?',
      whereArgs: [childId],
    );
    return maps.map(_mapToMedication).toList();
  }

  Future<int> updateMedicationSyncStatus(String recordId, String status) async {
    final db = await database;
    if (db == null) return 0;
    return await db.update(
      'medication_record',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // ─────────────────────────────────────────────
  // CRUD cho DiseaseReport
  // ─────────────────────────────────────────────

  Future<int> insertDiseaseReport(DiseaseReport report) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'disease_report',
      _diseaseReportToMap(report),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiseaseReport>> getAllDiseaseReports() async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('disease_report');
    return maps.map(_mapToDiseaseReport).toList();
  }

  Future<int> updateDiseaseReportSyncStatus(String reportId, String status) async {
    final db = await database;
    if (db == null) return 0;
    return await db.update(
      'disease_report',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  // ─────────────────────────────────────────────
  // Mappers (Ánh xạ các model)
  // ─────────────────────────────────────────────

  Map<String, dynamic> _childToMap(ChildProfile child) {
    return {
      'id': child.id,
      'qrCode': child.qrCode,
      'fullName': child.fullName,
      'dateOfBirth': child.dateOfBirth.toIso8601String(),
      'gender': child.gender,
      'motherName': child.motherName,
      'motherPhone': child.motherPhone,
      'village': child.village,
      'commune': child.commune,
      'district': child.district,
      'status': child.status.name,
      'nextVaccine': child.nextVaccine,
      'nextDue': child.nextDue.toIso8601String(),
      'lateDays': child.lateDays,
    };
  }

  ChildProfile _mapToChild(
    Map<String, dynamic> map,
    List<VaccinationRecord> vaccinations,
    List<MedicationRecord> medications,
  ) {
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
    );
  }

  Map<String, dynamic> _vaccinationToMap(VaccinationRecord rec) {
    return {
      'id': rec.id,
      'childId': rec.childId,
      'vaccineId': rec.vaccineId,
      'vaccineName': rec.vaccineName,
      'doseNumber': rec.doseNumber,
      'lotNumber': rec.lotNumber,
      'administeredBy': rec.administeredBy,
      'reactions': rec.reactions,
      'reactionSeverity': rec.reactionSeverity.name,
      'storageTemperature': rec.storageTemperature,
      'administeredAt': rec.administeredAt.toIso8601String(),
      'syncStatus': rec.syncStatus.name,
    };
  }

  VaccinationRecord _mapToVaccination(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'] as String,
      childId: map['childId'] as String,
      vaccineId: map['vaccineId'] as String,
      vaccineName: map['vaccineName'] as String,
      doseNumber: map['doseNumber'] as int,
      lotNumber: map['lotNumber'] as String,
      administeredBy: map['administeredBy'] as String,
      reactions: map['reactions'] as String?,
      reactionSeverity: ReactionSeverity.values.firstWhere((e) => e.name == map['reactionSeverity']),
      storageTemperature: map['storageTemperature'] as double?,
      administeredAt: DateTime.parse(map['administeredAt'] as String),
      syncStatus: SyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
    );
  }

  Map<String, dynamic> _medicationToMap(MedicationRecord rec) {
    return {
      'id': rec.id,
      'childId': rec.childId,
      'medicationId': rec.medicationId,
      'medicationName': rec.medicationName,
      'dosage': rec.dosage,
      'administeredBy': rec.administeredBy,
      'administeredAt': rec.administeredAt.toIso8601String(),
      'syncStatus': rec.syncStatus.name,
      'notes': rec.notes,
    };
  }

  MedicationRecord _mapToMedication(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'] as String,
      childId: map['childId'] as String,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      dosage: map['dosage'] as String,
      administeredBy: map['administeredBy'] as String,
      administeredAt: DateTime.parse(map['administeredAt'] as String),
      syncStatus: SyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> _diseaseReportToMap(DiseaseReport rep) {
    return {
      'id': rep.id,
      'diseaseTypeId': rep.diseaseTypeId,
      'diseaseName': rep.diseaseName,
      'patientName': rep.patientName,
      'patientAge': rep.patientAge,
      'patientGender': rep.patientGender,
      'village': rep.village,
      'commune': rep.commune,
      'symptoms': jsonEncode(rep.symptoms),
      'onsetDate': rep.onsetDate.toIso8601String(),
      'reportedBy': rep.reportedBy,
      'reportedAt': rep.reportedAt.toIso8601String(),
      'urgency': rep.urgency.name,
      'syncStatus': rep.syncStatus.name,
      'notes': rep.notes,
      'relatedChildId': rep.relatedChildId,
    };
  }

  DiseaseReport _mapToDiseaseReport(Map<String, dynamic> map) {
    return DiseaseReport(
      id: map['id'] as String,
      diseaseTypeId: map['diseaseTypeId'] as String,
      diseaseName: map['diseaseName'] as String,
      patientName: map['patientName'] as String,
      patientAge: map['patientAge'] as int,
      patientGender: map['patientGender'] as String,
      village: map['village'] as String,
      commune: map['commune'] as String,
      symptoms: List<String>.from(jsonDecode(map['symptoms'] as String) as List),
      onsetDate: DateTime.parse(map['onsetDate'] as String),
      reportedBy: map['reportedBy'] as String,
      reportedAt: DateTime.parse(map['reportedAt'] as String),
      urgency: DiseaseUrgency.values.firstWhere((e) => e.name == map['urgency']),
      syncStatus: SyncStatus.values.firstWhere((e) => e.name == map['syncStatus']),
      notes: map['notes'] as String?,
      relatedChildId: map['relatedChildId'] as String?,
    );
  }
}
