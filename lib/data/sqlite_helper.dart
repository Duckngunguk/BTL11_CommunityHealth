import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import 'master_data.dart';

class SqliteHelper {
  SqliteHelper._internal();
  static final SqliteHelper instance = SqliteHelper._internal();

  Database? _database;
  bool _ftsSupported = false;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      debugPrint(
          '⚠️ SQLite database not available on this platform ($e). Falling back to memory/demo data.');
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'community_health.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating SQLite tables...');

    // 1. Table users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT,
        fullName TEXT,
        email TEXT,
        phone TEXT,
        role TEXT,
        status TEXT,
        createdAt TEXT,
        token TEXT,
        assignedCommune TEXT,
        password TEXT,
        passwordHash TEXT,
        linkedChildIds TEXT
      )
    ''');

    // 2. Table children
    await db.execute('''
      CREATE TABLE children (
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
        lateDays INTEGER,
        lastSyncAt TEXT
      )
    ''');

    // 3. Table children_fts (FTS5 virtual table for fast search) - optional per platform
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE children_fts USING fts5(
          id,
          fullName,
          qrCode,
          motherName
        )
      ''');
      _ftsSupported = true;
    } catch (e) {
      _ftsSupported = false;
      debugPrint(
          'ℹ️ FTS5 virtual table not supported on this platform SQLite build ($e). Skipping FTS5 table.');
    }

    // 4. Table vaccinations
    await db.execute('''
      CREATE TABLE vaccinations (
        id TEXT PRIMARY KEY,
        childId TEXT,
        vaccineId TEXT,
        vaccineName TEXT,
        doseNumber INTEGER,
        lotNumber TEXT,
        administeredBy TEXT,
        reactions TEXT,
        administeredAt TEXT,
        syncStatus TEXT
      )
    ''');

    // 5. Table medications
    await db.execute('''
      CREATE TABLE medications (
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

    // 6. Table disease_reports
    await db.execute('''
      CREATE TABLE disease_reports (
        id TEXT PRIMARY KEY,
        childId TEXT,
        patientName TEXT,
        diseaseType TEXT,
        village TEXT,
        commune TEXT,
        district TEXT,
        reportedAt TEXT,
        reportedBy TEXT,
        symptoms TEXT,
        syncStatus TEXT,
        status TEXT,
        severity TEXT,
        notes TEXT
      )
    ''');

    // 7. Table audit_logs
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        action TEXT,
        performedBy TEXT,
        userRole TEXT,
        timestamp TEXT,
        details TEXT
      )
    ''');

    // 8. Table sync_batches
    await db.execute('''
      CREATE TABLE sync_batches (
        id TEXT PRIMARY KEY,
        deviceId TEXT,
        healthworkerId TEXT,
        vaccinationIds TEXT,
        status TEXT,
        uploadedAt TEXT,
        errorMessage TEXT
      )
    ''');

    // Seed Initial Demo Data
    await _seedDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading SQLite table from $oldVersion to $newVersion...');
    if (oldVersion < 2) {
      // 1. Add lastSyncAt column to children
      try {
        await db.execute('ALTER TABLE children ADD COLUMN lastSyncAt TEXT;');
      } catch (e) {
        debugPrint('Column lastSyncAt already exists or error adding: $e');
      }

      // 2. Create children_fts table
      try {
        await db.execute('DROP TABLE IF EXISTS children_fts;');
        await db.execute('''
          CREATE VIRTUAL TABLE children_fts USING fts5(
            id,
            fullName,
            qrCode,
            motherName
          )
        ''');
        await db.execute('''
          INSERT INTO children_fts(id, fullName, qrCode, motherName)
          SELECT id, fullName, qrCode, motherName FROM children;
        ''');
        _ftsSupported = true;
      } catch (e) {
        _ftsSupported = false;
        debugPrint('ℹ️ FTS5 table skipped during upgrade: $e');
      }

      // 4. Create sync_batches table
      await db.execute('DROP TABLE IF EXISTS sync_batches;');
      await db.execute('''
        CREATE TABLE sync_batches (
          id TEXT PRIMARY KEY,
          deviceId TEXT,
          healthworkerId TEXT,
          vaccinationIds TEXT,
          status TEXT,
          uploadedAt TEXT,
          errorMessage TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN passwordHash TEXT;');
      await db.execute('ALTER TABLE users ADD COLUMN linkedChildIds TEXT;');
      await db.update(
        'users',
        {'linkedChildIds': 'CH002'},
        where: 'username = ?',
        whereArgs: ['parent.demo'],
      );
      final childCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM children'),
          ) ??
          0;
      if (childCount == 0) await _seedDemoChildren(db);
    }
  }

  Future<void> _seedDemoData(Database db) async {
    debugPrint('Seeding initial login accounts to SQLite...');

    // Seed only the default login users so we can log in
    for (var u in demoUsers) {
      await db.insert('users', u.toMap());
    }
    await _seedDemoChildren(db);
  }

  Future<void> _seedDemoChildren(Database db) async {
    for (final child in demoChildren) {
      await db.insert(
        'children',
        child.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (_ftsSupported) {
        await db.insert(
          'children_fts',
          {
            'id': child.id,
            'fullName': child.fullName,
            'qrCode': child.qrCode,
            'motherName': child.motherName,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final record in child.vaccinations) {
        await db.insert(
          'vaccinations',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final record in child.medications) {
        await db.insert(
          'medications',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  // --- Child Methods ---
  Future<List<ChildProfile>> getChildren() async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('children');

    List<ChildProfile> list = [];
    for (var map in maps) {
      final childId = map['id'] as String;

      // Get vaccinations
      final List<Map<String, dynamic>> vMaps = await db.query(
        'vaccinations',
        where: 'childId = ?',
        whereArgs: [childId],
      );
      final vaccinations =
          vMaps.map((v) => VaccinationRecord.fromMap(v)).toList();

      // Get medications
      final List<Map<String, dynamic>> mMaps = await db.query(
        'medications',
        where: 'childId = ?',
        whereArgs: [childId],
      );
      final medications =
          mMaps.map((m) => MedicationRecord.fromMap(m)).toList();

      list.add(ChildProfile.fromMap(map,
          vaccinations: vaccinations, medications: medications));
    }
    return list;
  }

  // FTS Search offline method
  Future<List<ChildProfile>> searchChildrenOffline(String query) async {
    final db = await database;
    if (db == null) return [];
    if (query.trim().isEmpty) {
      return getChildren();
    }

    List<Map<String, dynamic>> maps = [];
    if (_ftsSupported) {
      try {
        final cleanQuery = query.replaceAll('\'', '\'\'').trim();
        maps = await db.rawQuery('''
          SELECT children.* FROM children
          INNER JOIN children_fts ON children.id = children_fts.id
          WHERE children_fts MATCH ?
        ''', ['$cleanQuery*']);
      } catch (_) {
        maps = [];
      }
    }

    if (maps.isEmpty) {
      final term = '%${query.trim()}%';
      maps = await db.query(
        'children',
        where:
            'fullName LIKE ? OR motherName LIKE ? OR qrCode LIKE ? OR village LIKE ?',
        whereArgs: [term, term, term, term],
      );
    }

    List<ChildProfile> list = [];
    for (var map in maps) {
      final childId = map['id'] as String;

      // Get vaccinations
      final List<Map<String, dynamic>> vMaps = await db.query(
        'vaccinations',
        where: 'childId = ?',
        whereArgs: [childId],
      );
      final vaccinations =
          vMaps.map((v) => VaccinationRecord.fromMap(v)).toList();

      // Get medications
      final List<Map<String, dynamic>> mMaps = await db.query(
        'medications',
        where: 'childId = ?',
        whereArgs: [childId],
      );
      final medications =
          mMaps.map((m) => MedicationRecord.fromMap(m)).toList();

      list.add(ChildProfile.fromMap(map,
          vaccinations: vaccinations, medications: medications));
    }
    return list;
  }

  Future<void> insertChild(ChildProfile child) async {
    final db = await database;
    if (db == null) return;
    await db.insert('children', child.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (_ftsSupported) {
      try {
        await db.insert(
            'children_fts',
            {
              'id': child.id,
              'fullName': child.fullName,
              'qrCode': child.qrCode,
              'motherName': child.motherName,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (_) {}
    }
  }

  Future<void> updateChild(ChildProfile child) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'children',
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
    if (_ftsSupported) {
      try {
        await db.insert(
            'children_fts',
            {
              'id': child.id,
              'fullName': child.fullName,
              'qrCode': child.qrCode,
              'motherName': child.motherName,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (_) {}
    }
  }

  Future<void> deleteChild(String childId) async {
    final db = await database;
    if (db == null) return;
    await db.delete('children', where: 'id = ?', whereArgs: [childId]);
    if (_ftsSupported) {
      try {
        await db.delete('children_fts', where: 'id = ?', whereArgs: [childId]);
      } catch (_) {}
    }
    await db.delete('vaccinations', where: 'childId = ?', whereArgs: [childId]);
    await db.delete('medications', where: 'childId = ?', whereArgs: [childId]);
  }

  // --- Vaccination Record Methods ---
  Future<void> insertVaccination(VaccinationRecord record) async {
    final db = await database;
    if (db == null) return;
    await db.insert('vaccinations', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVaccinationSyncStatus(String id, String syncStatus) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'vaccinations',
      {'syncStatus': syncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Medication Record Methods ---
  Future<void> insertMedication(MedicationRecord record) async {
    final db = await database;
    if (db == null) return;
    await db.insert('medications', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMedicationSyncStatus(String id, String syncStatus) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'medications',
      {'syncStatus': syncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Disease Report Methods ---
  Future<List<DiseaseReport>> getDiseaseReports() async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('disease_reports');
    return maps.map((r) => DiseaseReport.fromMap(r)).toList();
  }

  Future<void> insertDiseaseReport(DiseaseReport report) async {
    final db = await database;
    if (db == null) return;
    await db.insert('disease_reports', report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDiseaseReportStatus(String id, String status) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'disease_reports',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateDiseaseReportSyncStatus(
      String id, String syncStatus) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'disease_reports',
      {'syncStatus': syncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- User Methods ---
  Future<List<UserModel>> getUsers() async {
    final db = await database;
    if (db == null) return demoUsers;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((u) => UserModel.fromMap(u)).toList();
  }

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    if (db == null) return;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUserStatus(String id, String status) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'users',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateUserSession(UserModel user) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'users',
        {
          'token': user.token,
          'password': null,
          'passwordHash': user.passwordHash,
          'linkedChildIds': user.linkedChildIds.join(','),
        },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Audit Log Methods ---
  Future<List<SystemAuditLog>> getAuditLogs() async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps =
        await db.query('audit_logs', orderBy: 'timestamp DESC');
    return maps.map((log) => SystemAuditLog.fromMap(log)).toList();
  }

  Future<void> insertAuditLog(SystemAuditLog log) async {
    final db = await database;
    if (db == null) return;
    await db.insert('audit_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Sync Batch Methods ---
  Future<List<SyncBatch>> getSyncBatches() async {
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps =
        await db.query('sync_batches', orderBy: 'uploadedAt DESC');
    return maps.map((b) => SyncBatch.fromMap(b)).toList();
  }

  Future<void> insertSyncBatch(SyncBatch batch) async {
    final db = await database;
    if (db == null) return;
    await db.insert('sync_batches', batch.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSyncBatch(SyncBatch batch) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'sync_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }
}
