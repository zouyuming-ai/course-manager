import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String avatarColor;

  @HiveField(3)
  String grade;

  @HiveField(4)
  String className;

  Student({
    required this.id,
    required this.name,
    this.avatarColor = '#FFC857',
    required this.grade,
    this.className = '',
  });
}
