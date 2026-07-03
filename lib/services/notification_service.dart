import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';
import '../models/reminder.dart';

/// 本地推送通知服务
/// 负责：1) 课程提醒（每天早上推送当天课表概要）
///       2) 书包提醒（每晚推送明天书包准备清单）
///       3) 自定义提醒（按 Reminder 的日期时间推送）
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化 timezone + 通知插件
  Future<void> init() async {
    if (_initialized) return;

    // 初始化 timezone 数据
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 点击通知后的回调（后续可导航到对应页面）
        print('Notification tapped: ${response.id} payload=${response.payload}');
      },
    );

    _initialized = true;
  }

  /// 请求通知权限（Android 13+ 需要显式请求）
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  // ---- 通知渠道 ----

  static const AndroidNotificationChannel _courseChannel = AndroidNotificationChannel(
    'course_reminder',
    '课程提醒',
    description: '提醒当天课程安排',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _bagChannel = AndroidNotificationChannel(
    'bag_reminder',
    '书包提醒',
    description: '提醒准备明天书包',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _customChannel = AndroidNotificationChannel(
    'custom_reminder',
    '自定义提醒',
    description: '用户自定义的提醒通知',
    importance: Importance.high,
  );

  // ---- 立即发送通知 ----

  /// 发送课程提醒（当天课表概要）
  Future<void> showCourseReminder(String studentName, String courseSummary) async {
    await _plugin.show(
      1001,
      '📚 $studentName今天的课',
      courseSummary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _courseChannel.id,
          _courseChannel.name,
          channelDescription: _courseChannel.description,
          importance: _courseChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'course_reminder',
    );
  }

  /// 发送书包提醒（明天书包准备清单）
  Future<void> showBagReminder(String studentName, String bagSummary) async {
    await _plugin.show(
      1002,
      '🎒 $studentName明天书包准备',
      bagSummary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _bagChannel.id,
          _bagChannel.name,
          channelDescription: _bagChannel.description,
          importance: _bagChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'bag_reminder',
    );
  }

  /// 发送自定义提醒通知
  Future<void> showCustomReminder(String content, String category, String reminderId) async {
    final id = reminderId.hashCode & 0x7FFFFFFF;
    await _plugin.show(
      id,
      '🔔 $category提醒',
      content,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _customChannel.id,
          _customChannel.name,
          channelDescription: _customChannel.description,
          importance: _customChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'custom:$reminderId',
    );
  }

  // ---- 定时通知 ----

  /// 定时课程提醒 — 每天早上指定时间推送
  Future<void> scheduleDailyCourseReminder({
    required String studentName,
    required String courseSummary,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      2001,
      '📚 $studentName今天的课',
      courseSummary,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _courseChannel.id,
          _courseChannel.name,
          channelDescription: _courseChannel.description,
          importance: _courseChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'course_reminder',
    );
  }

  /// 定时书包提醒 — 每天晚上指定时间推送
  Future<void> scheduleDailyBagReminder({
    required String studentName,
    required String bagSummary,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      2002,
      '🎒 $studentName明天书包准备',
      bagSummary,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _bagChannel.id,
          _bagChannel.name,
          channelDescription: _bagChannel.description,
          importance: _bagChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bag_reminder',
    );
  }

  /// 定时自定义提醒 — 按日期和时间推送
  Future<void> scheduleCustomReminder({
    required String reminderId,
    required String content,
    required String category,
    required DateTime reminderDate,
    required String reminderTime,
    required int notifyBeforeMinutes,
  }) async {
    final id = reminderId.hashCode & 0x7FFFFFFF;
    final timeParts = reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 7;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    final scheduledDate = DateTime(
      reminderDate.year, reminderDate.month, reminderDate.day,
      hour, minute,
    ).subtract(Duration(minutes: notifyBeforeMinutes));

    final now = DateTime.now();

    // 如果提醒时间已过，跳过
    if (scheduledDate.isBefore(now)) return;

    final diff = scheduledDate.difference(now);

    // 对于短时间内的提醒（< 30 分钟），使用 Future.delayed 确保准时触发
    if (diff.inMinutes < 30) {
      _pendingDelays[id] = Future.delayed(diff, () {
        // 检查是否已被取消
        if (_cancelledDelays.contains(id)) {
          _cancelledDelays.remove(id);
          return;
        }
        _plugin.show(
          id,
          '🔔 $category提醒',
          content,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _customChannel.id,
              _customChannel.name,
              channelDescription: _customChannel.description,
              importance: _customChannel.importance,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: 'custom:$reminderId',
        );
      });
      return;
    }

    // 对于较远期的提醒，使用 zonedSchedule（精确模式）
    await _plugin.zonedSchedule(
      id,
      '🔔 $category提醒',
      content,
      TZDateTime.from(scheduledDate, local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _customChannel.id,
          _customChannel.name,
          channelDescription: _customChannel.description,
          importance: _customChannel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'custom:$reminderId',
    );
  }

  /// 存储短延时通知的 Future，用于取消
  final Map<int, Future<void>> _pendingDelays = {};

  /// 取消自定义提醒
  Future<void> cancelCustomReminder(String reminderId) async {
    final id = reminderId.hashCode & 0x7FFFFFFF;
    // 取消 Future.delayed（如果有）
    // 注意：Dart 的 Future.delayed 无法真正取消，
    // 但我们可以避免显示通知，通过标记来实现
    _cancelledDelays.add(id);
    _pendingDelays.remove(id);
    await _plugin.cancel(id);
  }

  final Set<int> _cancelledDelays = {};

  /// 在 App 启动时重新调度所有未完成的提醒
  /// 由 ReminderProvider 在初始化时调用
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    // 先取消所有旧通知
    await cancelAll();

    // 按每条的 notifyBeforeMinutes 重新调度
    for (final r in reminders) {
      if (r.isCompleted) continue;
      scheduleCustomReminder(
        reminderId: r.id,
        content: r.content,
        category: r.category,
        reminderDate: r.reminderDate,
        reminderTime: r.reminderTime,
        notifyBeforeMinutes: r.notifyBeforeMinutes,
      );
    }
  }

  // ---- 取消通知（全部） ----

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ---- 辅助 ----

  TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = TZDateTime.now(local);
    var scheduled = TZDateTime(local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
