import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/mobile/mobile_shell.dart';
import 'screens/parent/parent_shell.dart';
import 'state/app_store.dart';
import 'widgets/common_widgets.dart';
import 'data/sqlite_helper.dart';
import 'models/models.dart';
import 'services/firebase_sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background Task triggered: $task');
    try {
      final dbHelper = SqliteHelper.instance;
      final dbChildren = await dbHelper.getChildren();

      final connection = await Connectivity().checkConnectivity();
      final hasConnection =
          connection.any((result) => result != ConnectivityResult.none);

      if (!hasConnection) {
        debugPrint('🔄 Background Task aborted: No network connectivity.');
        return Future.value(true);
      }

      final pendingVaccinations = dbChildren
          .expand((child) => child.vaccinations)
          .where((v) => v.syncStatus == VaccinationSyncStatus.pending)
          .toList();

      if (pendingVaccinations.isNotEmpty) {
        final batch = SyncBatch(
          id: 'BATCH-BG-${DateTime.now().millisecondsSinceEpoch}',
          deviceId: 'device-sapa-bg',
          healthworkerId: 'worker-bg-sync',
          vaccinationIds: pendingVaccinations.map((v) => v.id).toList(),
          status: SyncBatchStatus.uploaded,
          uploadedAt: DateTime.now(),
        );

        await dbHelper.insertSyncBatch(batch);

        final syncService = FirebaseSyncService.instance;
        final success =
            await syncService.syncBatchUpload(batch, pendingVaccinations);

        if (success) {
          for (var record in pendingVaccinations) {
            await dbHelper.updateVaccinationSyncStatus(
                record.id, VaccinationSyncStatus.synced.name);
          }
          final processedBatch = SyncBatch(
            id: batch.id,
            deviceId: batch.deviceId,
            healthworkerId: batch.healthworkerId,
            vaccinationIds: batch.vaccinationIds,
            status: SyncBatchStatus.processed,
            uploadedAt: batch.uploadedAt,
          );
          await dbHelper.updateSyncBatch(processedBatch);
          debugPrint(
              '🔄 Background Task: Sync batch ${batch.id} completed successfully.');
        } else {
          final errorBatch = SyncBatch(
            id: batch.id,
            deviceId: batch.deviceId,
            healthworkerId: batch.healthworkerId,
            vaccinationIds: batch.vaccinationIds,
            status: SyncBatchStatus.error,
            uploadedAt: batch.uploadedAt,
            errorMessage: 'Background batch upload failed.',
          );
          await dbHelper.updateSyncBatch(errorBatch);
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('🔄 Background Task Exception: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    await Workmanager().registerPeriodicTask(
      'sync-pending-task',
      'periodicSyncTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('🔄 Workmanager initialized successfully.');
  } catch (e) {
    debugPrint('⚠️ Workmanager initialization skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: AppScope(
        child: CommunityHealthApp(),
      ),
    ),
  );
}

class CommunityHealthApp extends StatelessWidget {
  const CommunityHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommunityHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen, brightness: Brightness.light),
        scaffoldBackgroundColor: pageBackground,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E0DC))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E0DC))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryGreen, width: 1.6)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
        ),
      ),
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  AppMode? _mode;

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return LoginScreen(onLogin: (mode) => setState(() => _mode = mode));
    }
    if (_mode == AppMode.admin) {
      return AdminShell(onLogout: () => setState(() => _mode = null));
    }
    if (_mode == AppMode.parent) {
      return ParentShell(onLogout: () => setState(() => _mode = null));
    }
    return MobileShell(onLogout: () => setState(() => _mode = null));
  }
}
