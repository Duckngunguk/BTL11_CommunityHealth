import 'package:flutter/widgets.dart';

import '../data/demo_data.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  AppStore()
      : children = List<ChildProfile>.from(demoChildren),
        lastSyncAt = DateTime(2026, 7, 23, 16, 40);

  final List<ChildProfile> children;
  bool isOnline = false;
  bool isSyncing = false;
  DateTime lastSyncAt;

  int get pendingCount {
    final pendingVaccines = children
        .expand((child) => child.vaccinations)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    final pendingMedications = children
        .expand((child) => child.medications)
        .where((record) => record.syncStatus == VaccinationSyncStatus.pending)
        .length;
    return pendingVaccines + pendingMedications;
  }

  int get lateCount => children
      .where((child) => child.status == ChildVaccinationStatus.late)
      .length;

  int get dueSoonCount => children
      .where((child) => child.status == ChildVaccinationStatus.dueSoon)
      .length;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void addChild(ChildProfile child) {
    children.insert(0, child);
    notifyListeners();
  }

  void updateChild(ChildProfile child) {
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) return;
    children[index] = child;
    notifyListeners();
  }

  void deleteChild(String childId) {
    children.removeWhere((item) => item.id == childId);
    notifyListeners();
  }

  void addVaccination(String childId, VaccinationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      vaccinations: [...children[index].vaccinations, record],
    );
    notifyListeners();
  }

  void addMedication(String childId, MedicationRecord record) {
    final index = children.indexWhere((child) => child.id == childId);
    if (index == -1) return;
    children[index] = children[index].copyWith(
      medications: [...children[index].medications, record],
    );
    notifyListeners();
  }

  Future<void> syncPending() async {
    if (!isOnline || pendingCount == 0) return;
    isSyncing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    for (var i = 0; i < children.length; i++) {
      final updatedVaccinations = children[i].vaccinations.map((record) {
        return record.syncStatus == VaccinationSyncStatus.pending
            ? record.copyWith(syncStatus: VaccinationSyncStatus.synced)
            : record;
      }).toList();

      final updatedMedications = children[i].medications.map((record) {
        return record.syncStatus == VaccinationSyncStatus.pending
            ? record.copyWith(syncStatus: VaccinationSyncStatus.synced)
            : record;
      }).toList();

      children[i] = children[i].copyWith(
        vaccinations: updatedVaccinations,
        medications: updatedMedications,
      );
    }

    lastSyncAt = DateTime.now();
    isSyncing = false;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({
    super.key,
    required AppStore notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trong widget tree.');
    return scope!.notifier!;
  }
}
