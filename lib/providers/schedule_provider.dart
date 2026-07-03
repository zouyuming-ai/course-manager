import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/course_schedule.dart';
import '../models/subject_color.dart';
import '../theme/design_tokens.dart';
import '../utils/subject_colors.dart';

/// 课表管理 Provider
class ScheduleProvider extends ChangeNotifier {
  final Box<CourseSchedule> _scheduleBox = Hive.box<CourseSchedule>('schedules');
  final Box<SubjectColor> _colorBox = Hive.box<SubjectColor>('subjectColors');

  List<CourseSchedule> _schedules = [];
  List<SubjectColor> _subjectColors = [];

  List<CourseSchedule> get schedules => _schedules;
  List<SubjectColor> get subjectColors => _subjectColors;

  /// 初始化：从 Hive 读取数据
  ScheduleProvider() {
    _loadFromBox();
  }

  void _loadFromBox() {
    _schedules = _scheduleBox.values.toList();
    _subjectColors = _colorBox.values.toList();
    notifyListeners();
  }

  /// 获取指定学生的所有课表
  List<CourseSchedule> getSchedulesForStudent(String studentId, String semesterId, {String? currentWeekType}) {
    return _schedules.where((s) =>
      s.studentId == studentId &&
      s.semesterId == semesterId &&
      _filterByWeekType(s.weekType, currentWeekType)
    ).toList();
  }

  /// 获取指定星期几的课表
  List<CourseSchedule> getScheduleForDay(String studentId, String semesterId, int dayOfWeek, {String? currentWeekType}) {
    return _schedules.where((s) =>
      s.studentId == studentId &&
      s.semesterId == semesterId &&
      s.dayOfWeek == dayOfWeek &&
      _filterByWeekType(s.weekType, currentWeekType)
    ).toList();
  }

  /// 单双周过滤逻辑
  /// weekType: 课程设置的周类型（'A'/'B'/'ALL'）
  /// currentWeekType: 当前是A周还是B周（'A'/'B'），如果为null则不过滤
  bool _filterByWeekType(String weekType, String? currentWeekType) {
    if (currentWeekType == null) return true; // 不过滤
    if (weekType == 'ALL') return true; // 每周都上的课
    return weekType == currentWeekType; // 只显示对应周的课
  }

  /// 获取指定科目的颜色（十六进制字符串）
  /// 优先返回自定义颜色，否则返回空字符串
  String getSubjectColor(String studentId, String subject) {
    final customColor = _subjectColors.where((c) =>
      c.studentId == studentId && c.subject == subject
    ).firstOrNull;
    return customColor?.color ?? '';
  }

  /// 获取指定科目的颜色（Color 对象）
  /// 统一颜色获取逻辑：自定义 > 预设 > DesignTokens > 回退色
  Color getSubjectColorValue(String subject) {
    // 1. 先查自定义颜色（全局或学生级）
    final customColor = _subjectColors.where((c) =>
      c.subject == subject
    ).firstOrNull;
    if (customColor != null && customColor.color.isNotEmpty) {
      return hexToColor(customColor.color);
    }

    // 2. 再查预设颜色映射
    final presetHex = presetSubjectColorHex[subject];
    if (presetHex != null) {
      return hexToColor(presetHex);
    }

    // 3. 再查 DesignTokens 中的科目颜色
    final designColor = DesignTokens.subjectColors[subject];
    if (designColor != null) {
      return designColor;
    }

    // 4. 最终回退到强调色
    return DesignTokens.accent;
  }

  /// 获取所有用户自定义科目名称集合
  Set<String> getCustomSubjectNames() {
    return _subjectColors.map((c) => c.subject).toSet();
  }

  /// 获取所有已知科目名称列表（预设 + 自定义 + 已有课表，去重排序）
  List<String> getAllKnownSubjects() {
    final subjects = <String>{};

    // 从预设映射获取
    subjects.addAll(presetSubjectColorHex.keys);

    // 从自定义颜色中获取（用户可能为新科目设置了颜色）
    for (final sc in _subjectColors) {
      subjects.add(sc.subject);
    }

    // 从已有课表中获取（发现新科目）
    for (final s in _schedules) {
      if (s.subject.isNotEmpty) {
        subjects.add(s.subject);
      }
    }

    return subjects.toList()..sort();
  }

  /// 添加课表条目
  void addSchedule(CourseSchedule schedule) {
    _scheduleBox.put(schedule.id, schedule);
    _schedules = _scheduleBox.values.toList();
    notifyListeners();
  }

  /// 更新课表条目
  void updateSchedule(CourseSchedule schedule) {
    schedule.save();
    _schedules = _scheduleBox.values.toList();
    notifyListeners();
  }

  /// 删除课表条目
  void deleteSchedule(String id) {
    _scheduleBox.delete(id);
    _schedules = _scheduleBox.values.toList();
    notifyListeners();
  }

  /// 更新课表条目的科目名称（用于重命名科目）
  void updateScheduleSubject(String id, String newSubject) {
    final schedule = _scheduleBox.get(id);
    if (schedule != null) {
      final updated = CourseSchedule(
        id: schedule.id,
        studentId: schedule.studentId,
        semesterId: schedule.semesterId,
        dayOfWeek: schedule.dayOfWeek,
        period: schedule.period,
        subject: newSubject,
        classroom: schedule.classroom,
        weekType: schedule.weekType,
      );
      _scheduleBox.put(id, updated);
      _schedules = _scheduleBox.values.toList();
      notifyListeners();
    }
  }

  /// 设置科目自定义颜色
  void setSubjectColor(SubjectColor subjectColor) {
    _colorBox.put(subjectColor.id, subjectColor);
    _subjectColors = _colorBox.values.toList();
    notifyListeners();
  }

  /// 删除科目自定义颜色（恢复默认）
  void deleteSubjectColor(String id) {
    _colorBox.delete(id);
    _subjectColors = _colorBox.values.toList();
    notifyListeners();
  }

  /// 初始化白鹤小学二（7）班默认课表
  /// 来源：用户提供的课表照片
  /// 节次: 早读(0) + 第1~8节(1~8)
  /// 星期: 周一(1) ~ 周五(5)
  Future<void> initBaiheDefaultSchedules(String studentId, String semesterId) async {
    // 白鹤小学二（7）班课程表
    // 格式: List<List<String?>> 其中 [dayIndex][periodIndex] = 科目名
    // dayIndex: 0=周一, 1=周二, ... 4=周五
    // periodIndex: 0=早读, 1=第1节, ... 8=第8节
    const defaultSchedule = <List<String?>>[
      // 周一
      ['外语', '语文', '数学', '体育与健康', '写字', '英拓', '语文', '美术', '课后服务'],
      // 周二
      ['数学', '外语', '语文', '劳动技术', '唱游', '快乐活动', '体育与健康', '语文', '课后服务'],
      // 周三
      ['外语', '数学', '美术', '唱游', '语文', '快乐活动', '体活', '兴活', '课后服务'],
      // 周四
      ['语文', '语文', '外语', '体育与健康', '综合活动', '快乐活动', '科学', '道德与法治', '课后服务'],
      // 周五
      ['语文', '数学', '语文', '体育与健康', '道德与法治', '科学', '少先队活动', null, null],
    ];

    for (int day = 1; day <= 5; day++) {
      final daySchedule = defaultSchedule[day - 1];
      for (int period = 0; period <= 8; period++) {
        final subject = daySchedule[period];
        if (subject == null || subject.isEmpty) continue;

        final schedule = CourseSchedule(
          id: '${studentId}_${semesterId}_d${day}_p${period}',
          studentId: studentId,
          semesterId: semesterId,
          dayOfWeek: day,
          period: period,
          subject: subject,
          weekType: 'ALL',
        );
        addSchedule(schedule);
      }
    }
  }
}
