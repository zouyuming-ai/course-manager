import 'package:hive/hive.dart';

part 'course_schedule.g.dart';

@HiveType(typeId: 2)
class CourseSchedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String semesterId;

  @HiveField(3)
  int dayOfWeek; // 1-5 表示周一到周五

  @HiveField(4)
  int period; // 0=早读, 1-8=第1~8节

  @HiveField(5)
  String subject;

  @HiveField(6)
  String classroom;

  @HiveField(7)
  String weekType; // A/B/ALL 表示单双周或每周

  CourseSchedule({
    required this.id,
    required this.studentId,
    required this.semesterId,
    required this.dayOfWeek,
    required this.period,
    required this.subject,
    this.classroom = '',
    this.weekType = 'ALL',
  });
}
