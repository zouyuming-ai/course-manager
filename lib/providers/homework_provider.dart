import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/homework.dart';

/// 家庭作业管理 Provider
/// 支持两级结构：科目（Subject Group）→ 多个作业任务（Tasks）
class HomeworkProvider extends ChangeNotifier {
  Box<Homework>? _box;
  List<Homework> _homeworks = [];
  List<Homework> get homeworks => _homeworks;

  HomeworkProvider() {
    _initBox();
  }

  void _initBox() {
    try {
      _box = Hive.box<Homework>('homework');
      if (_box != null && _box!.isOpen) {
        _loadFromBox();
        debugPrint('✅ HomeworkProvider 初始化成功，共 ${_homeworks.length} 条数据');
      } else {
        debugPrint('⚠️ Homework box 未打开，数据为空');
        _homeworks = [];
      }
    } catch (e) {
      debugPrint('❌ HomeworkProvider 初始化失败: $e');
      _homeworks = [];
    }
  }

  void _loadFromBox() {
    if (_box == null || !_box!.isOpen) {
      _homeworks = [];
      return;
    }
    try {
      _homeworks = _box!.values.toList();
    } catch (e) {
      debugPrint('❌ HomeworkProvider._loadFromBox 失败: $e');
      _homeworks = [];
    }
  }

  void _reload() {
    _loadFromBox();
    notifyListeners();
  }

  // ========== 基础查询 ==========

  /// 获取指定学生的所有作业
  List<Homework> getHomeworksForStudent(String studentId) {
    return _homeworks.where((h) => h.studentId == studentId).toList();
  }

  /// 获取指定学生的待完成作业
  List<Homework> getPendingHomework(String studentId) {
    return _homeworks.where((h) => h.studentId == studentId && !h.isCompleted).toList();
  }

  /// 获取指定学生的已完成作业
  List<Homework> getCompletedHomework(String studentId) {
    return _homeworks.where((h) => h.studentId == studentId && h.isCompleted).toList();
  }

  /// 获取指定日期的作业
  List<Homework> getHomeworkForDate(String studentId, DateTime date) {
    return _homeworks.where((h) =>
      h.studentId == studentId &&
      h.dueDate.year == date.year &&
      h.dueDate.month == date.month &&
      h.dueDate.day == date.day
    ).toList();
  }

  // ========== 分组查询（两级结构核心）==========

  /// 获取按 (科目, 截止日期) 分组的待完成作业
  Map<String, List<Homework>> getGroupedPendingHomework(String studentId) {
    final pending = getPendingHomework(studentId);
    final Map<String, List<Homework>> grouped = {};
    for (final hw in pending) {
      grouped.putIfAbsent(hw.groupKey, () => []).add(hw);
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.taskOrder.compareTo(b.taskOrder));
    }
    return grouped;
  }

  /// 获取按 (科目, 截止日期) 分组的已完成作业
  Map<String, List<Homework>> getGroupedCompletedHomework(String studentId) {
    final completed = getCompletedHomework(studentId);
    final Map<String, List<Homework>> grouped = {};
    for (final hw in completed) {
      grouped.putIfAbsent(hw.groupKey, () => []).add(hw);
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.taskOrder.compareTo(b.taskOrder));
    }
    return grouped;
  }

  /// 从分组键解析科目名和截止日期
  /// groupKey格式：科目名|YYYY-M-D（如 "语文|2026-6-30"）
  static (String subject, DateTime dueDate) parseGroupKey(String groupKey) {
    final pipeIndex = groupKey.indexOf('|');
    if (pipeIndex <= 0 || pipeIndex >= groupKey.length - 1) {
      // 兼容旧版 _ 分隔符格式
      final parts = groupKey.split('_');
      if (parts.length >= 2) {
        final subject = parts.sublist(0, parts.length - 1).join('_');
        final datePart = parts.last;
        final dp = datePart.split('-').map(int.parse).toList();
        if (dp.length == 3) return (subject, DateTime(dp[0], dp[1], dp[2]));
      }
      return (groupKey, DateTime.now());
    }
    final subject = groupKey.substring(0, pipeIndex);
    final dateStr = groupKey.substring(pipeIndex + 1);
    final dateParts = dateStr.split('-').map(int.parse).toList();
    if (dateParts.length == 3) {
      return (subject, DateTime(dateParts[0], dateParts[1], dateParts[2]));
    }
    return (subject, DateTime.now());
  }

  /// 获取某科目组在某个截止日期下的最大 taskOrder
  int _getNextTaskOrder(String studentId, String subject, DateTime dueDate) {
    final sameGroup = _homeworks.where((h) =>
      h.studentId == studentId &&
      h.subject == subject &&
      h.dueDate.year == dueDate.year &&
      h.dueDate.month == dueDate.month &&
      h.dueDate.day == dueDate.day
    );
    if (sameGroup.isEmpty) return 1;
    return sameGroup.map((h) => h.taskOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  // ========== CRUD 操作 ==========

  /// 添加单个作业任务（自动分配序号）
  void addHomework(Homework homework) {
    if (_box == null || !_box!.isOpen) {
      debugPrint('❌ addHomework: box 未打开！尝试重新获取');
      try {
        _box = Hive.box<Homework>('homework');
      } catch (_) {}
      if (_box == null || !_box!.isOpen) {
        debugPrint('💥 addHomework: box 仍然不可用');
        return;
      }
    }
    try {
      // 自动分配任务序号
      if (homework.taskOrder <= 0) {
        homework.taskOrder = _getNextTaskOrder(homework.studentId, homework.subject, homework.dueDate);
      }
      _box!.put(homework.id, homework);
      _reload();
      debugPrint('✅ addHomework: ${homework.subject} #${homework.taskOrder} "${homework.content}" 已保存');
    } catch (e) {
      debugPrint('❌ addHomework 失败: $e');
    }
  }

  /// 更新作业
  void updateHomework(Homework homework) {
    if (_box == null || !_box!.isOpen) return;
    try {
      _box!.put(homework.id, homework);
      _reload();
    } catch (e) {
      debugPrint('❌ updateHomework 失败: $e');
    }
  }

  /// 标记完成/未完成（单任务级别）
  void toggleComplete(String id) {
    final homework = _homeworks.where((h) => h.id == id).firstOrNull;
    if (homework != null) {
      homework.isCompleted = !homework.isCompleted;
      homework.completedDate = homework.isCompleted ? DateTime.now() : null;
      homework.save();
      _reload();
    }
  }

  /// 删除作业
  void deleteHomework(String id) {
    if (_box == null || !_box!.isOpen) return;
    _box!.delete(id);
    _reload();
  }

  /// 删除整个科目组的所有任务
  void deleteHomeworkGroup(String studentId, String subject, DateTime dueDate) {
    if (_box == null || !_box!.isOpen) return;
    final toDelete = _homeworks.where((h) =>
      h.studentId == studentId &&
      h.subject == subject &&
      h.dueDate.year == dueDate.year &&
      h.dueDate.month == dueDate.month &&
      h.dueDate.day == dueDate.day
    ).toList();
    for (final hw in toDelete) {
      _box!.delete(hw.id);
    }
    _reload();
  }
}
