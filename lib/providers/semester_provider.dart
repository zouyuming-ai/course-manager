import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/semester.dart';

/// 学期管理 Provider
class SemesterProvider extends ChangeNotifier {
  final Box<Semester> _box = Hive.box<Semester>('semesters');

  List<Semester> _semesters = [];
  Semester? _activeSemester;

  List<Semester> get semesters => _semesters;
  Semester? get activeSemester => _activeSemester;

  /// 初始化：从 Hive 读取数据
  SemesterProvider() {
    _loadFromBox();
  }

  void _loadFromBox() {
    _semesters = _box.values.toList();
    // 尝试找到标记为活跃的学期
    final activeList = _semesters.where((s) => s.isActive).toList();

    // 清理数据：如果发现多个活跃学期，只保留第一个
    if (activeList.length > 1) {
      for (int i = 1; i < activeList.length; i++) {
        activeList[i].isActive = false;
        activeList[i].save();
      }
      _semesters = _box.values.toList(); // 重新加载
    }

    _activeSemester = activeList.isNotEmpty ? activeList.first : null;
    if (_activeSemester == null && _semesters.isNotEmpty) {
      _activeSemester = _semesters.first;
    }
    notifyListeners();
  }

  /// 设置当前活跃学期
  void setActiveSemester(String id) {
    final semester = _semesters.where((s) => s.id == id).firstOrNull;
    if (semester != null) {
      // 取消其他学期的活跃状态
      for (final s in _semesters) {
        if (s.isActive) {
          s.isActive = false;
          s.save();
        }
      }
      semester.isActive = true;
      semester.save();
      _activeSemester = semester;
      notifyListeners();
    }
  }

  /// 添加学期
  void addSemester(Semester semester) {
    _box.put(semester.id, semester);
    _semesters = _box.values.toList();

    // 如果新学期标记为活跃，先取消其他学期的活跃状态
    if (semester.isActive) {
      for (final s in _semesters) {
        if (s.id != semester.id && s.isActive) {
          s.isActive = false;
          s.save();
        }
      }
      _activeSemester = semester;
    } else if (_activeSemester == null && _semesters.isNotEmpty) {
      // 如果没有活跃学期，自动设置第一个为活跃
      _activeSemester = _semesters.first;
      _activeSemester!.isActive = true;
      _activeSemester!.save();
    }

    notifyListeners();
  }

  /// 删除学期
  void deleteSemester(String id) {
    _box.delete(id);
    _semesters = _box.values.toList();
    if (_activeSemester?.id == id) {
      _activeSemester = _semesters.isNotEmpty ? _semesters.first : null;
      if (_activeSemester != null) {
        _activeSemester!.isActive = true;
        _activeSemester!.save();
      }
    }
    notifyListeners();
  }

  /// 更新学期
  void updateSemester(Semester semester) {
    semester.save();
    _semesters = _box.values.toList();
    _activeSemester = _semesters.where((s) => s.isActive).firstOrNull;
    notifyListeners();
  }
}
