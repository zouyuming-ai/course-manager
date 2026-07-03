/// 日期辅助工具

/// 获取当前星期几（1=周一, 5=周五, 6=周六, 7=周日）
int getCurrentDayOfWeek() {
  final weekday = DateTime.now().weekday;
  return weekday;
}

/// 判断是否是周末
bool isWeekend(DateTime date) {
  return date.weekday >= 6;
}

/// 判断今天是否是周末
bool isTodayWeekend() {
  return isWeekend(DateTime.now());
}

/// 获取星期几的中文名称
String getDayName(int dayOfWeek) {
  const dayNames = {
    1: '周一',
    2: '周二',
    3: '周三',
    4: '周四',
    5: '周五',
    6: '周六',
    7: '周日',
  };
  return dayNames[dayOfWeek] ?? '';
}

/// 获取星期几的完整中文名称
String getDayFullName(int dayOfWeek) {
  const dayNames = {
    1: '星期一',
    2: '星期二',
    3: '星期三',
    4: '星期四',
    5: '星期五',
    6: '星期六',
    7: '星期日',
  };
  return dayNames[dayOfWeek] ?? '';
}

/// 格式化日期为 "MM/dd" 格式
String formatDateShort(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

/// 格式化日期为 "yyyy-MM-dd" 格式
String formatDateFull(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// 格式化日期为中文显示 "M月d日"
String formatDateChinese(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// 格式化日期为中文完整显示 "yyyy年M月d日"
String formatDateChineseFull(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

/// 获取明天的日期
DateTime getTomorrow() {
  return DateTime.now().add(const Duration(days: 1));
}

/// 获取明天是星期几
int getTomorrowDayOfWeek() {
  return getTomorrow().weekday;
}

/// 计算两个日期之间的天数差
int daysBetween(DateTime start, DateTime end) {
  return end.difference(start).inDays;
}

/// 判断日期是否是今天
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// 判断日期是否是明天
bool isTomorrow(DateTime date) {
  final tomorrow = getTomorrow();
  return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
}
