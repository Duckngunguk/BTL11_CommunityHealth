import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Mức độ ưu tiên của thông báo
enum NotificationPriority { info, warning, urgent }

/// Đại diện cho một thông báo trong hệ thống
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.childId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type; // 'late_vaccine', 'due_soon', 'disease_alert', 'system'
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? childId;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      priority: priority,
      timestamp: timestamp,
      childId: childId,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Dịch vụ Thông báo: In-App Banner + FCM (khi Firebase production sẵn sàng)
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notificationStream => _controller.stream;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Phát sinh thông báo nhắc tiêm chủng từ danh sách trẻ
  void generateVaccineReminders(List<ChildProfile> children) {
    final now = DateTime.now();

    for (final child in children) {
      if (child.status == ChildVaccinationStatus.late) {
        final existing = _notifications.any(
            (n) => n.childId == child.id && n.type == 'late_vaccine');
        if (!existing) {
          final notification = AppNotification(
            id: 'NOTIF-LATE-${child.id}',
            title: '⚠️ Trẻ trễ lịch tiêm chủng!',
            body:
                '${child.fullName} tại ${child.village} đã trễ ${child.lateDays} ngày. Vui lòng đưa trẻ đến tiêm sớm nhất!',
            type: 'late_vaccine',
            priority: NotificationPriority.urgent,
            timestamp: now,
            childId: child.id,
          );
          _pushNotification(notification);
        }
      } else if (child.status == ChildVaccinationStatus.dueSoon) {
        final nextDue = child.nextDue;
        final daysLeft = nextDue.difference(now).inDays;
        if (daysLeft <= 3 && daysLeft >= 0) {
          final existing = _notifications.any(
              (n) => n.childId == child.id && n.type == 'due_soon');
          if (!existing) {
            final notification = AppNotification(
              id: 'NOTIF-DUE-${child.id}',
              title: '🔔 Nhắc lịch tiêm chủng sắp đến',
              body:
                  '${child.fullName} cần tiêm ${child.nextVaccine} trong $daysLeft ngày nữa (${nextDue.day}/${nextDue.month}/${nextDue.year}).',
              type: 'due_soon',
              priority: NotificationPriority.warning,
              timestamp: now,
              childId: child.id,
            );
            _pushNotification(notification);
          }
        }
      }
    }
  }

  /// Phát sinh thông báo cảnh báo dịch bệnh
  void generateDiseaseAlert({
    required String diseaseName,
    required String location,
    required int caseCount,
  }) {
    final notification = AppNotification(
      id: 'NOTIF-DISEASE-${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 Cảnh báo dịch bệnh tại địa phương!',
      body:
          'Phát hiện $caseCount ca nghi ngờ $diseaseName tại $location. Theo dõi sức khoẻ trẻ và báo cáo ngay khi có triệu chứng!',
      type: 'disease_alert',
      priority: NotificationPriority.urgent,
      timestamp: DateTime.now(),
    );
    _pushNotification(notification);
  }

  /// Gửi thông báo hệ thống (Admin phê duyệt tài khoản, v.v.)
  void sendSystemNotification({
    required String title,
    required String body,
  }) {
    final notification = AppNotification(
      id: 'NOTIF-SYS-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: 'system',
      priority: NotificationPriority.info,
      timestamp: DateTime.now(),
    );
    _pushNotification(notification);
  }

  void _pushNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _controller.add(List.unmodifiable(_notifications));
    debugPrint('🔔 [Notification] ${notification.title}: ${notification.body}');
  }

  /// Đánh dấu thông báo đã đọc
  void markAsRead(String notificationId) {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _controller.add(List.unmodifiable(_notifications));
    }
  }

  /// Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _controller.add(List.unmodifiable(_notifications));
  }

  void dispose() {
    _controller.close();
  }
}
