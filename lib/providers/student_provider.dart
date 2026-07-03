import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/student.dart';

/// 学生管理 Provider
class StudentProvider extends ChangeNotifier {
  final Box<Student> _box = Hive.box<Student>('students');

  List<Student> _students = [];
  Student? _activeStudent;

  List<Student> get students => _students;
  Student? get activeStudent => _activeStudent;

  /// 初始化：从 Hive 读取数据
  StudentProvider() {
    _loadFromBox();
  }

  void _loadFromBox() {
    _students = _box.values.toList();
    if (_students.isNotEmpty && _activeStudent == null) {
      _activeStudent = _students.first;
    }
    notifyListeners();
  }

  /// 添加学生
  void addStudent(Student student) {
    _box.put(student.id, student);
    _students = _box.values.toList();
    if (_activeStudent == null) {
      _activeStudent = student;
    }
    notifyListeners();
  }

  /// 更新学生信息
  void updateStudent(Student student) {
    student.save();
    _students = _box.values.toList();
    notifyListeners();
  }

  /// 删除学生
  void deleteStudent(String id) {
    _box.delete(id);
    _students = _box.values.toList();
    if (_activeStudent?.id == id) {
      _activeStudent = _students.isNotEmpty ? _students.first : null;
    }
    notifyListeners();
  }

  /// 设置当前活跃学生
  void setActiveStudent(String id) {
    final student = _students.where((s) => s.id == id).firstOrNull;
    if (student != null) {
      _activeStudent = student;
      notifyListeners();
    }
  }
}
