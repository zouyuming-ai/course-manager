import 'package:hive/hive.dart';

part 'subject_color.g.dart';

@HiveType(typeId: 3)
class SubjectColor extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String subject;

  @HiveField(3)
  String color;

  SubjectColor({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.color,
  });
}
