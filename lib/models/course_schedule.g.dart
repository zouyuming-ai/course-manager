// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseScheduleAdapter extends TypeAdapter<CourseSchedule> {
  @override
  final int typeId = 2;

  @override
  CourseSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseSchedule(
      id: fields[0] as String,
      studentId: fields[1] as String,
      semesterId: fields[2] as String,
      dayOfWeek: fields[3] as int,
      period: fields[4] as int,
      subject: fields[5] as String,
      classroom: fields[6] as String,
      weekType: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CourseSchedule obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.semesterId)
      ..writeByte(3)
      ..write(obj.dayOfWeek)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.subject)
      ..writeByte(6)
      ..write(obj.classroom)
      ..writeByte(7)
      ..write(obj.weekType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
