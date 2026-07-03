import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/time_slot.dart';

/// 时间点配置 Provider
/// 管理当前学期的上下课时间配置（早读、第1~8节的时间段和标签）
class TimeSlotProvider extends ChangeNotifier {
  List<TimeSlot> _timeSlots = [];
  String? _currentSemesterId;

  /// 获取当前时间点列表
  List<TimeSlot> get timeSlots => _timeSlots;

  /// 获取当前学期ID
  String? get currentSemesterId => _currentSemesterId;

  /// 设置当前学期并加载对应时间点
  void setSemester(String semesterId) {
    if (_currentSemesterId == semesterId) return;
    _currentSemesterId = semesterId;
    _loadTimeSlots();
  }

  /// 从 Hive 加载时间点数据
  void _loadTimeSlots() {
    if (_currentSemesterId == null) {
      _timeSlots = [];
      notifyListeners();
      return;
    }
    final box = Hive.box<TimeSlot>('timeSlots');
    _timeSlots = box.values
        .where((ts) => ts.semesterId == _currentSemesterId)
        .toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    notifyListeners();
  }

  /// 获取指定节次的时间点
  TimeSlot? getTimeSlot(int period) {
    try {
      return _timeSlots.firstWhere((ts) => ts.period == period);
    } catch (_) {
      return null;
    }
  }

  /// 获取所有时间点的显示标签列表
  List<String> get periodLabels {
    final labels = <String>[];
    for (int i = 0; i < _timeSlots.length; i++) {
      final ts = _timeSlots[i];
      labels.add(ts.displayLabel);
    }
    // 如果时间点数量不足9个，补充默认标签
    while (labels.length < 9) {
      final period = labels.length;
      labels.add(period == 0 ? '早读' : '第$period节');
    }
    return labels;
  }

  /// 获取所有时间点的显示时间段列表
  List<String> get periodTimes {
    final times = <String>[];
    for (int i = 0; i < _timeSlots.length; i++) {
      final ts = _timeSlots[i];
      times.add(ts.displayTime);
    }
    // 如果时间点数量不足9个，补充空字符串
    while (times.length < 9) {
      times.add('');
    }
    return times;
  }

  /// 添加或更新时间点
  Future<void> saveTimeSlot(TimeSlot timeSlot) async {
    final box = Hive.box<TimeSlot>('timeSlots');
    await box.put(timeSlot.id, timeSlot);
    _loadTimeSlots();
  }

  /// 删除时间点
  Future<void> deleteTimeSlot(String id) async {
    final box = Hive.box<TimeSlot>('timeSlots');
    await box.delete(id);
    _loadTimeSlots();
  }

  /// 初始化默认时间点（首次使用时调用）
  /// 白鹤小学真实作息时间表（来自二（7）班课表）
  Future<void> initDefaultTimeSlots(String semesterId) async {
    final defaultSlots = [
      // 早读（图片未标明时间，按惯例设为7:50-8:15）
      TimeSlot(id: '${semesterId}_0', semesterId: semesterId, period: 0, startTime: '07:50', endTime: '08:15', label: '早读'),
      // 第一节：8:20 -- 8:55
      TimeSlot(id: '${semesterId}_1', semesterId: semesterId, period: 1, startTime: '08:20', endTime: '08:55', label: '一'),
      // 第二节：9:30—10:05
      TimeSlot(id: '${semesterId}_2', semesterId: semesterId, period: 2, startTime: '09:30', endTime: '10:05', label: '二'),
      // 第三节：10:15—10:55
      TimeSlot(id: '${semesterId}_3', semesterId: semesterId, period: 3, startTime: '10:15', endTime: '10:55', label: '三'),
      // 第四节：11:05—11:40
      TimeSlot(id: '${semesterId}_4', semesterId: semesterId, period: 4, startTime: '11:05', endTime: '11:40', label: '四'),
      // 第五节(五)：1:00—1:35 (13:00-13:35)
      TimeSlot(id: '${semesterId}_5', semesterId: semesterId, period: 5, startTime: '13:00', endTime: '13:35', label: '五'),
      // 第六节(六)：1:45—2:25 (13:45-14:25)
      TimeSlot(id: '${semesterId}_6', semesterId: semesterId, period: 6, startTime: '13:45', endTime: '14:25', label: '六'),
      // 第七节(七)：2:35—3:15 (14:35-15:15)
      TimeSlot(id: '${semesterId}_7', semesterId: semesterId, period: 7, startTime: '14:35', endTime: '15:15', label: '七'),
      // 第八节(八)：3:25—4:00 (15:25-16:00)
      TimeSlot(id: '${semesterId}_8', semesterId: semesterId, period: 8, startTime: '15:25', endTime: '16:00', label: '八'),
    ];

    for (final slot in defaultSlots) {
      await saveTimeSlot(slot);
    }
  }

  /// 检查当前学期是否已配置时间点
  bool get hasTimeSlots => _timeSlots.isNotEmpty;
}
