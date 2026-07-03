import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

/// 提醒管理 Provider
/// 添加/删除提醒时自动调度/取消本地推送通知
class ReminderProvider extends ChangeNotifier {
  final Box<Reminder> _box = Hive.box<Reminder>('reminders');
  final NotificationService _notif = NotificationService.instance;

  List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;

  /// 获取未完成的提醒
  List<Reminder> getPendingReminders(String studentId) {
    return _reminders.where((r) =>
      r.studentId == studentId && !r.isCompleted
    ).toList();
  }

  /// 获取已完成的提醒
  List<Reminder> getCompletedReminders(String studentId) {
    return _reminders.where((r) =>
      r.studentId == studentId && r.isCompleted
    ).toList();
  }

  /// 获取今日提醒
  List<Reminder> getTodayReminders(String studentId) {
    final today = DateTime.now();
    return _reminders.where((r) =>
      r.studentId == studentId &&
      !r.isCompleted &&
      r.reminderDate.year == today.year &&
      r.reminderDate.month == today.month &&
      r.reminderDate.day == today.day
    ).toList();
  }

  /// 初始化：从 Hive 读取数据 + 重新调度所有未完成提醒
  ReminderProvider() {
    _loadFromBox();
    _reschedulePendingNotifications();
  }

  void _loadFromBox() {
    _reminders = _box.values.toList();
    notifyListeners();
  }

  /// 应用启动时重新调度所有未完成的提醒
  void _reschedulePendingNotifications() {
    final pending = _reminders.where((r) => !r.isCompleted).toList();
    if (pending.isNotEmpty) {
      _notif.rescheduleAll(pending);
    }
  }

  /// 添加提醒 + 调度推送通知
  void addReminder(Reminder reminder) {
    _box.put(reminder.id, reminder);
    _reminders = _box.values.toList();
    notifyListeners();
    // 自动调度通知
    _notif.scheduleCustomReminder(
      reminderId: reminder.id,
      content: reminder.content,
      category: reminder.category,
      reminderDate: reminder.reminderDate,
      reminderTime: reminder.reminderTime,
      notifyBeforeMinutes: reminder.notifyBeforeMinutes,
    );
  }

  /// 编辑/更新提醒 + 重新调度通知
  void updateReminder(Reminder reminder) {
    _box.put(reminder.id, reminder);
    _reminders = _box.values.toList();
    notifyListeners();
    // 取消旧通知 + 重新调度
    _notif.cancelCustomReminder(reminder.id);
    if (!reminder.isCompleted) {
      _notif.scheduleCustomReminder(
        reminderId: reminder.id,
        content: reminder.content,
        category: reminder.category,
        reminderDate: reminder.reminderDate,
        reminderTime: reminder.reminderTime,
        notifyBeforeMinutes: reminder.notifyBeforeMinutes,
      );
    }
  }

  /// 标记完成/未完成 + 取消/恢复通知
  void toggleComplete(String id) {
    final reminder = _reminders.where((r) => r.id == id).firstOrNull;
    if (reminder != null) {
      reminder.isCompleted = !reminder.isCompleted;
      reminder.save();
      _reminders = _box.values.toList();
      notifyListeners();
      // 完成则取消通知，恢复则重新调度
      if (reminder.isCompleted) {
        _notif.cancelCustomReminder(reminder.id);
      } else {
        _notif.scheduleCustomReminder(
          reminderId: reminder.id,
          content: reminder.content,
          category: reminder.category,
          reminderDate: reminder.reminderDate,
          reminderTime: reminder.reminderTime,
          notifyBeforeMinutes: reminder.notifyBeforeMinutes,
        );
      }
    }
  }

  /// 删除提醒 + 取消通知
  void deleteReminder(String id) {
    _box.delete(id);
    _reminders = _box.values.toList();
    notifyListeners();
    _notif.cancelCustomReminder(id);
  }
}
