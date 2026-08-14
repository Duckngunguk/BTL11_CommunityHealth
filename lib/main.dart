import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final supportsBackgroundWork = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (supportsBackgroundWork) {
    try {
      await Workmanager().initialize(callbackDispatcher);
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
      theme: buildCommunityHealthTheme(),
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
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    if (store.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Route guard: the destination is derived only from the authenticated
    // account stored by AppStore. A role/mode sent by the UI is never trusted.
    final activeMode = store.currentUser == null
        ? null
        : switch (store.currentUser!.role) {
            UserRole.admin => AppMode.admin,
            UserRole.parent => AppMode.parent,
            UserRole.healthWorker => AppMode.mobile,
          };

    void logout() async {
      await store.logout();
      if (!mounted) return;
      setState(() {});
    }

    if (activeMode == AppMode.admin) {
      return AdminShell(onLogout: logout);
    }

    if (activeMode == AppMode.parent) {
      return ParentShell(
        onLogout: logout,
      );
    }
    if (activeMode == AppMode.mobile) {
      return MobileShell(
        onLogout: logout,
      );
    }

    return LoginScreen(
      onLogin: (_) => setState(() {}),
    );
  }
}
