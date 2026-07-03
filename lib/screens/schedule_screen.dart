import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/models/course_schedule.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/providers/reminder_provider.dart';
import 'package:course_manager/providers/time_slot_provider.dart';
import 'package:course_manager/widgets/course_cell.dart';
import 'package:course_manager/widgets/week_selector.dart';
import 'package:course_manager/widgets/reminder_summary_card.dart';
import 'package:course_manager/screens/empty_state.dart';
import 'package:course_manager/services/schedule_image_exporter.dart';

/// S1 周课表主页 — App 首页，最核心的界面
/// 设计规格：背景色跟随ThemeProvider，导航栏+日期选择器+课表网格+底部TabBar
/// 支持 showWeekend（显示周六周日列）和 showClassTime（显示上课时间段）

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// 当前选中日期
  late DateTime _selectedDate;

  /// 当前周的起始日（周一）
  late DateTime _weekStart;

  /// 课表网格截图Key（用于分享功能）
  final GlobalKey _scheduleGridKey = GlobalKey();

  /// 周类型筛选：null=当前周, 'A'=只看A周, 'B'=只看B周, 'ALL'=显示全部
  String? _weekTypeView;

  /// 9节课的时间标签：从 TimeSlotProvider 读取，兜底使用默认
  List<String> get _periodLabels {
    final timeSlotProvider = context.read<TimeSlotProvider>();
    if (timeSlotProvider.hasTimeSlots) {
      return timeSlotProvider.periodLabels;
    }
    return ['早读', '一', '二', '三', '四', '五', '六', '七', '八'];
  }

  /// 各节课时间段：从 TimeSlotProvider 读取，兜底使用默认
  List<String> get _periodTimes {
    final timeSlotProvider = context.read<TimeSlotProvider>();
    if (timeSlotProvider.hasTimeSlots) {
      return timeSlotProvider.periodTimes;
    }
    return [
      '7:50-8:20',   // 早读
      '8:30-9:10',   // 第一节
      '9:20-10:00',  // 第二节
      '10:20-11:00', // 第三节
      '11:10-11:50', // 第四节
      '14:00-14:40', // 第五节
      '14:50-15:30', // 第六节
      '15:40-16:20', // 第七节
      '16:30-17:10', // 第八节
    ];
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    // 计算本周周一
    _weekStart = _getWeekStart(now);
  }

  /// 获取某日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=周一 ... 7=周日
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 切换选中日期
  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;
    });
  }

  /// 切换周
  void _onWeekChanged(DateTime newWeekStart) {
    setState(() {
      _weekStart = newWeekStart;
      _selectedDate = newWeekStart;
    });
  }

  /// 获取明天提醒摘要文字列表
  List<String> _getTomorrowReminderTexts(ReminderProvider reminderProvider, ScheduleProvider scheduleProvider, String studentId, String semesterId, {String? currentWeekType}) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDayOfWeek = tomorrow.weekday; // 1-7

    // 只处理工作日（1-5），周末也处理（showWeekend开启时）
    if (tomorrowDayOfWeek > 7) return [];

    final tomorrowReminders = reminderProvider.getPendingReminders(studentId);
    final tomorrowSchedule = scheduleProvider.getScheduleForDay(studentId, semesterId, tomorrowDayOfWeek, currentWeekType: currentWeekType);

    // 提取明天的提醒
    final texts = <String>[];
    for (final reminder in tomorrowReminders) {
      if (reminder.reminderDate.year == tomorrow.year &&
          reminder.reminderDate.month == tomorrow.month &&
          reminder.reminderDate.day == tomorrow.day) {
        texts.add(reminder.content);
      }
    }

    // 如果明天有特殊科目（如体育），自动补充提醒
    final specialSubjects = tomorrowSchedule
        .where((s) => ['体育', '音乐', '美术', '唱游'].contains(s.subject))
        .map((s) => s.subject)
        .toSet();

    for (final subject in specialSubjects) {
      final reminderText = _getSubjectReminderText(subject);
      if (reminderText != null && !texts.contains(reminderText)) {
        texts.add(reminderText);
      }
    }

    return texts;
  }

  /// 科目提醒文字映射
  String? _getSubjectReminderText(String subject) {
    switch (subject) {
      case '体育': return '明天有体育课，记得带运动服';
      case '音乐': return '明天有音乐课，记得带乐器';
      case '美术': return '明天有美术课，记得带画具';
      case '唱游': return '明天有唱游课，记得穿舒适衣服';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final semesterProvider = context.watch<SemesterProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final timeSlotProvider = context.watch<TimeSlotProvider>();

    final accentColor = themeProvider.accentColor;
    final bgColor = themeProvider.bgColor;
    final showWeekend = themeProvider.showWeekend;
    final showClassTime = themeProvider.showClassTime;
    final fontScale = themeProvider.fontScale;

    final activeStudent = studentProvider.activeStudent;
    final activeSemester = semesterProvider.activeSemester;

    // 同步 TimeSlotProvider 的当前学期
    if (activeSemester != null && timeSlotProvider.currentSemesterId != activeSemester.id) {
      timeSlotProvider.setSemester(activeSemester.id);
    }

    // 如果没有学生或学期，显示空状态
    if (activeStudent == null || activeSemester == null) {
      return const ScheduleEmptyState();
    }

    // 获取当前周类型（A周或B周）
    final currentWeekType = activeSemester.currentWeekType;

    // 获取当前学期所有课表（未过滤，用于检查是否有AB周课程）
    final allUnfilteredSchedules = scheduleProvider.getSchedulesForStudent(
      activeStudent.id, activeSemester.id,
    );

    // 自动去重：同一(星期+节次+科目)只保留一条（优先保留weekType="ALL"的）
    final dedupedSchedules = <CourseSchedule>[];
    final seenKeys = <String>{};
    for (final s in allUnfilteredSchedules) {
      final key = '${s.dayOfWeek}_${s.period}_${s.subject}';
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        dedupedSchedules.add(s);
      } else if (s.weekType == 'ALL') {
        // 如果已有记录但新的是ALL版本，替换掉
        final idx = dedupedSchedules.indexWhere((e) =>
          '${e.dayOfWeek}_${e.period}_${e.subject}' == key);
        if (idx >= 0 && dedupedSchedules[idx].weekType != 'ALL') {
          dedupedSchedules[idx] = s;
        }
      }
    }

    // 二次清理：如果去重后某位置既有ALL又有非ALL记录，只保留ALL
    // 这处理了用户编辑课程后旧记录未删除的情况
    final cleanedSchedules = <CourseSchedule>[];
    final allKeys = <String>{};
    for (final s in dedupedSchedules) {
      final key = '${s.dayOfWeek}_${s.period}_${s.subject}';
      if (!allKeys.contains(key)) {
        allKeys.add(key);
        cleanedSchedules.add(s);
      } else {
        // 已有同位置的记录，如果是ALL则替换
        if (s.weekType == 'ALL') {
          final idx = cleanedSchedules.indexWhere((e) =>
            '${e.dayOfWeek}_${e.period}_${e.subject}' == key);
          if (idx >= 0) {
            cleanedSchedules[idx] = s;
          }
        }
        // 否则跳过（保留已有的ALL或第一条记录）
      }
    }

    // 调试：打印每个课程的weekType（使用print以确保在release模式下也能看到）
    print('[ScheduleScreen] ========== AB周检测 ==========');
    print('[ScheduleScreen] 原始课程=${allUnfilteredSchedules.length}, 去重后=${cleanedSchedules.length}');
    for (final s in cleanedSchedules) {
      print('[ScheduleScreen] subject="${s.subject}", weekType="${s.weekType}"');
    }

    // 检查是否有AB周课程（基于去重后的数据）
    final hasWeekTypeCourses = cleanedSchedules.any((s) {
      final wt = s.weekType.trim().toUpperCase();
      return wt == 'A' || wt == 'B';
    });

    print('[ScheduleScreen] hasWeekTypeCourses=$hasWeekTypeCourses');
    print('[ScheduleScreen] =============================');

    // 计算筛选周类型（支持用户手动切换查看A/B/全部）
    String? filterWeekType;
    if (_weekTypeView == null) {
      // 当前周模式：只显示与当前周类型匹配的课程
      filterWeekType = currentWeekType;
    } else if (_weekTypeView == 'ALL') {
      // 全部模式：不过滤
      filterWeekType = null;
    } else {
      // 指定A周或B周
      filterWeekType = _weekTypeView;
    }

    // 获取当前学期所有课表（根据单双周过滤，基于去重后的数据）
    final allSchedules = hasWeekTypeCourses
        ? cleanedSchedules.where((s) {
            if (filterWeekType == null) return true;
            if (s.weekType == 'ALL') return true;
            return s.weekType == filterWeekType;
          }).toList()
        : cleanedSchedules;

    // 获取明天提醒
    final reminderTexts = _getTomorrowReminderTexts(
      reminderProvider, scheduleProvider,
      activeStudent.id, activeSemester.id,
      currentWeekType: currentWeekType,
    );

    // 确定显示的列数：默认5列(周一~周五)，showWeekend时7列(含周六周日)
    final dayCount = showWeekend ? 7 : 5;
    final dayLabels = showWeekend
        ? ['一', '二', '三', '四', '五', '六', '日']
        : ['一', '二', '三', '四', '五'];

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildNavBar(activeStudent, accentColor, fontScale),

            // 周选择器
            WeekSelector(
              selectedDate: _selectedDate,
              weekStart: _weekStart,
              onDaySelected: _onDaySelected,
              onWeekChanged: _onWeekChanged,
            ),

            // 周类型筛选器（只在有AB周课程时显示）
            if (activeSemester != null && hasWeekTypeCourses)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 当前筛选状态
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: themeProvider.isDarkMode ? DesignTokens.textSecondary : DesignTokens.textAux3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '当前${activeSemester.currentWeekTypeDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.isDarkMode ? DesignTokens.textSecondary : DesignTokens.textAux3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // 当前筛选状态
                        Text(
                          _weekTypeView == null
                              ? '（当前周）'
                              : _weekTypeView == 'ALL'
                                  ? '（全部）'
                                  : '（${_weekTypeView}周）',
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 周类型切换按钮
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'CURRENT', label: Text('当前', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'A', label: Text('A周', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'B', label: Text('B周', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'ALL', label: Text('全部', style: TextStyle(fontSize: 12))),
                      ],
                      selected: {
                        _weekTypeView == null ? 'CURRENT' :
                        _weekTypeView == 'ALL' ? 'ALL' :
                        _weekTypeView!
                      },
                      onSelectionChanged: (values) {
                        setState(() {
                          final v = values.first;
                          if (v == 'CURRENT') {
                            _weekTypeView = null;
                          } else if (v == 'ALL') {
                            _weekTypeView = 'ALL';
                          } else {
                            _weekTypeView = v;
                          }
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // 如果没有AB周课程，不显示任何周类型信息
            // 只有在有AB周课程时才显示周类型相关UI
            const SizedBox(height: DesignTokens.elementGapLarge),

            // 提醒摘要卡片（有提醒才显示）
            ReminderSummaryCard(reminderTexts: reminderTexts),

                    // 课表网格
            Expanded(
              child: allSchedules.isEmpty
                  ? const ScheduleEmptyState()
                  : RepaintBoundary(
                      key: _scheduleGridKey,
                      child: _buildScheduleGrid(
                        scheduleProvider, activeStudent.id, activeSemester.id,
                        accentColor, bgColor, showWeekend, showClassTime,
                        dayCount, dayLabels, fontScale,
                        filterWeekType,  // 使用筛选后的周类型
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏：左侧学生头像/名称，右侧分享图标，标题"课程表"
  Widget _buildNavBar(Student activeStudent, Color accentColor, double fontScale) {
    return Container(
      height: DesignTokens.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
      child: Row(
        children: [
          // 左侧：学生头像+名称
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _parseAvatarColor(activeStudent.avatarColor),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                activeStudent.name.isNotEmpty ? activeStudent.name[0] : '?',
                style: const TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.card,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.elementGap),
          Text(
            activeStudent.name,
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSize * fontScale,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const Spacer(),
          // 中间标题
          Text(
            '课程表',
            style: TextStyle(
              fontSize: DesignTokens.titleSize * fontScale,
              fontWeight: DesignTokens.titleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const Spacer(),
          // 右侧：作业图标 + 添加课程按钮 + 分享图标
          IconButton(
            icon: const Icon(Icons.assignment_outlined, size: 22),
            color: DesignTokens.textSecondary,
            onPressed: () {
              context.push('/homework');
            },
            tooltip: '家庭作业',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: accentColor,
            onPressed: () {
              context.push('/students/${activeStudent.id}/course/add');
            },
            tooltip: '添加课程',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            color: DesignTokens.textSecondary,
            onPressed: () async {
              try {
                await ScheduleImageExporter.captureAndShare(
                  _scheduleGridKey, activeStudent.name,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('分享失败：$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 解析头像颜色字符串
  Color _parseAvatarColor(String colorStr) {
    try {
      if (colorStr.startsWith('#') && colorStr.length == 7) {
        final hex = colorStr.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return DesignTokens.accent;
  }

  /// 课表网格
  Widget _buildScheduleGrid(
    ScheduleProvider scheduleProvider, String studentId, String semesterId,
    Color accentColor, Color bgColor, bool showWeekend, bool showClassTime,
    int dayCount, List<String> dayLabels, double fontScale,
    String? filterWeekType,  // 周类型筛选参数
  ) {
    // 根据选中日期确定高亮列
    final selectedDayOfWeek = _selectedDate.weekday; // 1-7
    // 只有在显示范围内的列才高亮
    final highlightCol = (selectedDayOfWeek >= 1 && selectedDayOfWeek <= dayCount)
        ? selectedDayOfWeek - 1 : -1;

    // 周末列（第6、7列）用灰色文字标记
    final weekendCols = showWeekend ? [5, 6] : <int>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin),
      child: Column(
        children: [
          // 列标题行
          Row(
            children: [
              // 时间列（showClassTime时更宽）
              SizedBox(
                width: showClassTime ? 52 : 28,
                child: const SizedBox(),
              ),
              ...List.generate(dayCount, (col) => Expanded(
                child: Center(
                  child: Text(
                    dayLabels[col],
                    style: TextStyle(
                      fontSize: DesignTokens.auxSizeLarge * fontScale,
                      fontWeight: (col == highlightCol) ? FontWeight.w700 : FontWeight.w600,
                      color: (col == highlightCol) ? accentColor
                          : (weekendCols.contains(col) ? DesignTokens.textAux2 : DesignTokens.textSecondary),
                    ),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 9行课表格子（早读 + 第1~8节）
          Expanded(
            child: ListView.builder(
              itemCount: 9,
              itemBuilder: (context, row) {
                final periodLabel = _periodLabels[row];
                final periodTime = showClassTime ? _periodTimes[row] : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.elementGap - 2),
                  child: Row(
                    children: [
                      // 左侧：节次标签 + 可选时间段
                      SizedBox(
                        width: showClassTime ? 52 : 28,
                        child: showClassTime
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      periodLabel,
                                      style: TextStyle(
                                        fontSize: DesignTokens.auxSize,
                                        fontWeight: DesignTokens.auxWeight,
                                        color: DesignTokens.textAux1,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      periodTime!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: DesignTokens.textAux2,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    periodLabel,
                                    style: TextStyle(
                                      fontSize: DesignTokens.auxSize,
                                      fontWeight: DesignTokens.auxWeight,
                                      color: DesignTokens.textAux1,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      // 课程列格子
                      ...List.generate(dayCount, (col) {
                        final dayOfWeek = col + 1;
                        // row 0 = 早读(period 0), row 1-8 = 第1~8节(period 1-8)
                        final period = row; // 0=早读, 1-8=正式课

                        final courses = scheduleProvider.getScheduleForDay(
                          studentId, semesterId, dayOfWeek,
                          currentWeekType: filterWeekType,  // 使用筛选后的周类型
                        );
                        final course = courses.where((c) => c.period == period).firstOrNull;

                        // 使用 ScheduleProvider 的统一颜色获取方法（自定义 > 预设 > DesignTokens > 回退）
                        final subjectColor = course != null
                            ? scheduleProvider.getSubjectColorValue(course.subject)
                            : null;

                        // 选中列高亮背景
                        final isHighlighted = col == highlightCol;

                        // 周末列样式
                        final isWeekendCol = weekendCols.contains(col);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              decoration: isHighlighted && course == null
                                  ? BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                                    )
                                  : null,
                              child: Opacity(
                                opacity: isWeekendCol ? 0.6 : 1.0,
                                child: CourseCell(
                                  course: course,
                                  subjectColor: subjectColor,
                                  onTap: () {
                                    final path = course != null
                                        ? '/students/$studentId/course/add?courseId=${course.id}'
                                        : '/students/$studentId/course/add?day=$dayOfWeek&period=$period';
                                    context.push(path);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
