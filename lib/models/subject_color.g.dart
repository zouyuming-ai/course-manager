// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_color.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectColorAdapter extends TypeAdapter<SubjectColor> {
  @override
  final int typeId = 3;

  @override
  SubjectColor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectColor(
      id: fields[0] as String,
      studentId: fields[1] as String,
      subject: fields[2] as String,
      color: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectColor obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
