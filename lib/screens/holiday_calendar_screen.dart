import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/data/holiday_data.dart';

/// S18 假期/调休日历
/// 月历视图 + 中国法定假日标记 + 调休日标记
class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  late DateTime _currentMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedYear = _currentMonth.year;
  }

  /// 获取当前选中年份的假期数据
  YearHolidayData? get _currentYearData => getHolidayDataForYear(_selectedYear);

  String? _getHoliday(DateTime date) => _currentYearData?.getHoliday(date);
  bool _isWorkday(DateTime date) => _currentYearData?.isWorkday(date) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(title: const Text('假期日历')),
      body: Column(
        children: [
          // 年份选择
          _buildYearSelector(),
          // 月份导航
          _buildMonthNavigator(),
          // 星期标题
          _buildWeekdayHeader(),
          // 日历网格
          Expanded(child: _buildCalendarGrid()),
          // 图例
          _buildLegend(),
          const SizedBox(height: DesignTokens.cardGap),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.cardPadding, vertical: DesignTokens.elementGap),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedYear--;
              _currentMonth = DateTime(_selectedYear, _currentMonth.month);
            }),
          ),
          Text('$_selectedYear 年', style: const TextStyle(
            fontSize: DesignTokens.titleSize,
            fontWeight: DesignTokens.titleWeight,
            color: DesignTokens.textPrimary,
          )),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedYear++;
              _currentMonth = DateTime(_selectedYear, _currentMonth.month);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final monthNames = ['', '1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => setState(() {
              if (_currentMonth.month == 1) {
                _selectedYear--;
                _currentMonth = DateTime(_selectedYear, 12);
              } else {
                _currentMonth = DateTime(_selectedYear, _currentMonth.month - 1);
              }
            }),
          ),
          Text(monthNames[_currentMonth.month], style: const TextStyle(
            fontSize: DesignTokens.cardTitleSizeLarge,
            fontWeight: DesignTokens.cardTitleWeight,
            color: DesignTokens.textPrimary,
          )),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => setState(() {
              if (_currentMonth.month == 12) {
                _selectedYear++;
                _currentMonth = DateTime(_selectedYear, 1);
              } else {
                _currentMonth = DateTime(_selectedYear, _currentMonth.month + 1);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.elementGap),
      child: Row(
        children: weekdays.map((w) {
          final isWeekend = w == '六' || w == '日';
          return Expanded(
            child: Center(
              child: Text(w, style: TextStyle(
                fontSize: DesignTokens.auxSize,
                fontWeight: FontWeight.w600,
                color: isWeekend ? DesignTokens.weekendText : DesignTokens.textSecondary,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // 周一=1, 周日=7 → 转为索引：周一=0
    int firstWeekday = firstDay.weekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];

    // 前置空白
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final holiday = _getHoliday(date);
      final isWorkday = _isWorkday(date);
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      final isHoliday = holiday != null;

      cells.add(_buildDayCell(
        day: day,
        date: date,
        isToday: isToday,
        isWeekend: isWeekend,
        isHoliday: isHoliday,
        holidayName: holiday,
        isWorkday: isWorkday,
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
      childAspectRatio: 0.82,
      children: cells,
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required bool isToday,
    required bool isWeekend,
    required bool isHoliday,
    String? holidayName,
    required bool isWorkday,
  }) {
    Color? bgColor;
    Color textColor = DesignTokens.textPrimary;
    String? badge;

    if (isHoliday) {
      bgColor = DesignTokens.pendingBg;
      textColor = DesignTokens.pendingText;
      badge = holidayName;
    } else if (isWorkday) {
      bgColor = DesignTokens.successBg;
      textColor = DesignTokens.successText;
      badge = '补班';
    } else if (isWeekend) {
      textColor = DesignTokens.weekendText;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: DesignTokens.accent, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: isToday ? FontWeight.w700 : DesignTokens.bodyWeight,
              color: textColor,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 2),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(DesignTokens.pendingBg, DesignTokens.pendingText, '法定假日'),
          _buildLegendItem(DesignTokens.successBg, DesignTokens.successText, '调休补班'),
          _buildLegendItem(Colors.transparent, DesignTokens.weekendText, '周末'),
          _buildLegendItem(DesignTokens.accent, DesignTokens.textPrimary, '今天', isBorder: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color bg, Color text, String label, {bool isBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: isBorder ? Border.all(color: DesignTokens.accent, width: 2) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: DesignTokens.auxSize, color: text,
        )),
      ],
    );
  }
}
