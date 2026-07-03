import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';

/// 周选择器组件 — 顶部日期行，5或7个日期标签，当天高亮，支持滑动切换周
/// 支持 showWeekend 设置：true时显示7天(含周六周日)，false时只显示5天(周一~周五)

class WeekSelector extends StatefulWidget {
  /// 当前选中日期（用于高亮当天）
  final DateTime selectedDate;

  /// 当前显示的周起始日（周一）
  final DateTime weekStart;

  /// 选择某天的回调
  final ValueChanged<DateTime>? onDaySelected;

  /// 切换周的回调（滑动触发）
  final ValueChanged<DateTime>? onWeekChanged;

  const WeekSelector({
    super.key,
    required this.selectedDate,
    required this.weekStart,
    this.onDaySelected,
    this.onWeekChanged,
  });

  @override
  State<WeekSelector> createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  /// 周一到周日的中文标签
  static const List<String> _dayLabelsFull = ['一', '二', '三', '四', '五', '六', '日'];
  static const List<String> _dayLabelsShort = ['一', '二', '三', '四', '五'];

  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = widget.weekStart;
  }

  /// 计算当前周的天数（根据showWeekend设置）
  List<DateTime> _getWeekDays(bool showWeekend) {
    final count = showWeekend ? 7 : 5;
    return List.generate(count, (i) => _weekStart.add(Duration(days: i)));
  }

  /// 判断是否为当天
  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  /// 判断是否为选中日期
  bool _isSelected(DateTime day) {
    return day.year == widget.selectedDate.year &&
        day.month == widget.selectedDate.month &&
        day.day == widget.selectedDate.day;
  }

  /// 格式化日期：如 "6/27 一"
  String _formatDate(DateTime day, int index, bool showWeekend) {
    final labels = showWeekend ? _dayLabelsFull : _dayLabelsShort;
    return '${day.month}/${day.day} ${labels[index]}';
  }

  /// 判断是否为周末
  bool _isWeekend(DateTime day) {
    return day.weekday == 6 || day.weekday == 7; // 周六周日
  }

  /// 向前一周
  void _goToPreviousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    widget.onWeekChanged?.call(_weekStart);
    setState(() {});
  }

  /// 向后一周
  void _goToNextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    widget.onWeekChanged?.call(_weekStart);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final showWeekend = themeProvider.showWeekend;
    final accentColor = themeProvider.accentColor;
    final weekDays = _getWeekDays(showWeekend);
    final dayCount = showWeekend ? 7 : 5;

    return GestureDetector(
      // 左滑：下一周，右滑：上一周
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            _goToNextWeek();
          } else if (details.primaryVelocity! > 300) {
            _goToPreviousWeek();
          }
        }
      },
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
        ),
        child: Row(
          children: List.generate(dayCount, (index) {
            final day = weekDays[index];
            final isToday = _isToday(day);
            final isSelected = _isSelected(day);
            final isWeekend = _isWeekend(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDaySelected?.call(day),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    // 当天或选中日高亮
                    color: (isToday || isSelected)
                        ? accentColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  child: Text(
                    _formatDate(day, index, showWeekend),
                    style: TextStyle(
                      fontSize: DesignTokens.auxSizeLarge,
                      fontWeight: (isToday || isSelected) ? FontWeight.w600 : DesignTokens.auxWeight,
                      color: (isToday || isSelected)
                          ? DesignTokens.textPrimary
                          : isWeekend ? DesignTokens.textAux2 : DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
