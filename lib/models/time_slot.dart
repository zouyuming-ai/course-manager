import 'package:hive/hive.dart';

part 'time_slot.g.dart';

@HiveType(typeId: 4)
class TimeSlot extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String semesterId;

  @HiveField(2)
  int period; // 第几节课

  @HiveField(3)
  String startTime; // 格式 "08:00"

  @HiveField(4)
  String endTime; // 格式 "08:40"

  @HiveField(5)
  String label; // 时间段标签，如 "早读"、"第一节"、"第二节" 等

  TimeSlot({
    required this.id,
    required this.semesterId,
    required this.period,
    required this.startTime,
    required this.endTime,
    this.label = '', // 默认空字符串，兼容旧数据
  });

  /// 获取显示标签：优先使用自定义 label，否则返回默认标签
  static const List<String> defaultLabels = ['早读', '第一节', '第二节', '第三节', '第四节', '第五节', '第六节', '第七节', '第八节'];

  String get displayLabel {
    return label.isNotEmpty ? label : (period >= 0 && period < defaultLabels.length ? defaultLabels[period] : '第$period节');
  }

  /// 获取显示时间段
  String get displayTime => '$startTime-$endTime';
}
