import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 5)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String content;

  @HiveField(3)
  String category; // 表单/物品/活动

  @HiveField(4)
  DateTime reminderDate;

  @HiveField(5)
  String reminderTime; // 格式 "07:00"

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  String repeatRule; // none/daily/weekly/monthly

  @HiveField(8)
  int notifyBeforeMinutes;

  Reminder({
    required this.id,
    required this.studentId,
    required this.content,
    this.category = '物品',
    required this.reminderDate,
    this.reminderTime = '07:00',
    this.isCompleted = false,
    this.repeatRule = 'none',
    this.notifyBeforeMinutes = 30,
  });
}
