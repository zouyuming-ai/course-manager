import 'package:hive/hive.dart';

part 'semester.g.dart';

@HiveType(typeId: 1)
class Semester extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String schoolName;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime endDate;

  @HiveField(5)
  int totalWeeks;

  @HiveField(6)
  bool isActive;

  Semester({
    required this.id,
    required this.name,
    this.schoolName = '',
    required this.startDate,
    required this.endDate,
    this.totalWeeks = 20,
    this.isActive = false,
  });

  /// 计算当前是学期的第几周（从1开始）
  /// 使用整数除法：0-6天=第1周，7-13天=第2周，以此类推
  int get currentWeek {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 1;
    if (now.isAfter(endDate)) return totalWeeks;

    final daysDiff = now.difference(startDate).inDays;
    return (daysDiff ~/ 7) + 1;
  }

  /// 当前是A周还是B周
  /// 奇数周 = A周，偶数周 = B周
  String get currentWeekType {
    final week = currentWeek;
    return week % 2 == 1 ? 'A' : 'B';
  }

  /// 获取周类型显示文本
  String get currentWeekTypeDisplay {
    final week = currentWeek;
    final type = currentWeekType;
    return '第${week}周（${type}周）';
  }
}
