import 'package:hive/hive.dart';

part 'homework.g.dart';

@HiveType(typeId: 8)
class Homework extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String subject;

  @HiveField(3)
  String content; // 单个作业任务内容

  @HiveField(4)
  DateTime dueDate; // 截止日期（同一科目+日期的任务为一组）

  @HiveField(5)
  bool isCompleted; // 单个任务的完成状态

  @HiveField(6)
  String category; // 作业/背诵/练习/手工

  @HiveField(7)
  int taskOrder; // 任务序号（同科目组内自动递增）

  @HiveField(8)
  DateTime? completedDate; // 完成时间

  Homework({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.content,
    required this.dueDate,
    this.isCompleted = false,
    this.category = '作业',
    this.taskOrder = 0,
    this.completedDate,
  });

  /// 获取用于UI分组的键（科目+截止日期）
  /// 使用 | 作为分隔符，避免与科目名中的下划线冲突
  String get groupKey => '$subject|${dueDate.year}-${dueDate.month}-${dueDate.day}';
}
