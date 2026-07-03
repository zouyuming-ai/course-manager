import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/models/course_schedule.dart';

/// S14 一键复制课表
/// 从源学生复制课表到目标学生，支持选择星期、覆盖/合并模式
class CopyScheduleScreen extends StatefulWidget {
  const CopyScheduleScreen({super.key});

  @override
  State<CopyScheduleScreen> createState() => _CopyScheduleScreenState();
}

class _CopyScheduleScreenState extends State<CopyScheduleScreen> {
  Student? _sourceStudent;
  Student? _targetStudent;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  bool _overwrite = false; // false=合并, true=覆盖

  static const _dayNames = ['', '周一', '周二', '周三', '周四', '周五'];

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final activeSemester = context.watch<SemesterProvider>().activeSemester;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(title: const Text('一键复制课表')),
      body: students.length < 2
          ? _buildNeedMoreStudents()
          : activeSemester == null
              ? _buildNoSemester()
              : _buildContent(students, activeSemester.id),
    );
  }

  Widget _buildNeedMoreStudents() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 48, color: DesignTokens.textAux3),
          const SizedBox(height: DesignTokens.elementGapLarge),
          const Text('至少需要 2 名学生才能复制课表', style: TextStyle(
            fontSize: DesignTokens.cardTitleSize, color: DesignTokens.textSecondary,
          )),
          const SizedBox(height: DesignTokens.elementGap),
          const Text('请先在「学生」页面添加更多学生', style: TextStyle(
            fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
          )),
        ],
      ),
    );
  }

  Widget _buildNoSemester() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: DesignTokens.textAux3),
          SizedBox(height: DesignTokens.elementGapLarge),
          Text('请先设置当前学期', style: TextStyle(
            fontSize: DesignTokens.cardTitleSize, color: DesignTokens.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildContent(List<Student> students, String semesterId) {
    final canCopy = _sourceStudent != null && _targetStudent != null && _sourceStudent!.id != _targetStudent!.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.cardPadding),
            decoration: BoxDecoration(
              color: DesignTokens.pendingBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: DesignTokens.pendingText),
                const SizedBox(width: DesignTokens.elementGap),
                Expanded(
                  child: Text(
                    '将源学生的课表复制到目标学生，适合 twins 或同年级不同班的孩子',
                    style: const TextStyle(fontSize: DesignTokens.auxSize, color: DesignTokens.pendingText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 源学生
          _buildSectionLabel('从谁那里复制'),
          const SizedBox(height: DesignTokens.elementGap),
          _buildStudentSelector(
            students: students,
            selected: _sourceStudent,
            label: '选择源学生',
            onSelected: (s) => setState(() {
              _sourceStudent = s;
              if (_targetStudent?.id == s.id) _targetStudent = null;
            }),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 目标学生
          _buildSectionLabel('复制给谁'),
          const SizedBox(height: DesignTokens.elementGap),
          _buildStudentSelector(
            students: students.where((s) => s.id != _sourceStudent?.id).toList(),
            selected: _targetStudent,
            label: '选择目标学生',
            onSelected: (s) => setState(() => _targetStudent = s),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 选择星期
          _buildSectionLabel('复制哪些天'),
          const SizedBox(height: DesignTokens.elementGap),
          Wrap(
            spacing: DesignTokens.elementGap,
            runSpacing: DesignTokens.elementGap,
            children: [1, 2, 3, 4, 5].map((day) {
              final selected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? DesignTokens.accent : DesignTokens.pillBg,
                    borderRadius: BorderRadius.circular(DesignTokens.pillRadiusSmall),
                  ),
                  child: Text(
                    _dayNames[day],
                    style: TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: selected ? FontWeight.w600 : DesignTokens.bodyWeight,
                      color: selected ? DesignTokens.textPrimary : DesignTokens.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 覆盖/合并模式
          _buildSectionLabel('复制方式'),
          const SizedBox(height: DesignTokens.elementGap),
          _buildModeSelector(),
          const SizedBox(height: DesignTokens.cardGapLarge * 2),

          // 预览摘要
          if (canCopy) ...[
            _buildSummary(semesterId),
            const SizedBox(height: DesignTokens.cardGapLarge),
          ],

          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canCopy ? () => _doCopy(semesterId) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: DesignTokens.textPrimary,
                disabledBackgroundColor: DesignTokens.pillBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                ),
              ),
              child: Text(
                canCopy ? '确认复制' : '请选择学生',
                style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize,
                  fontWeight: DesignTokens.cardTitleWeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(
      fontSize: DesignTokens.cardTitleSize,
      fontWeight: DesignTokens.cardTitleWeight,
      color: DesignTokens.textPrimary,
    ));
  }

  Widget _buildStudentSelector({
    required List<Student> students,
    required Student? selected,
    required String label,
    required ValueChanged<Student> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: students.map((s) {
          final isSelected = selected?.id == s.id;
          return GestureDetector(
            onTap: () => onSelected(s),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.elementGap),
              padding: const EdgeInsets.all(DesignTokens.elementGapLarge),
              decoration: BoxDecoration(
                color: isSelected ? DesignTokens.accent.withValues(alpha: 0.15) : DesignTokens.pillBg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                border: isSelected ? Border.all(color: DesignTokens.accent, width: 2) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: DesignTokens.subjectColors[s.grade] ?? DesignTokens.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(s.name.isNotEmpty ? s.name.characters.first : '?', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: DesignTokens.bodySize,
                    )),
                  ),
                  const SizedBox(width: DesignTokens.elementGapLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(
                          fontSize: DesignTokens.cardTitleSize,
                          fontWeight: DesignTokens.cardTitleWeight,
                          color: DesignTokens.textPrimary,
                        )),
                        Text('${s.grade}${s.className}', style: const TextStyle(
                          fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
                        )),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: DesignTokens.accent, size: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _overwrite = false),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.cardPadding),
              decoration: BoxDecoration(
                color: DesignTokens.card,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                border: !_overwrite ? Border.all(color: DesignTokens.accent, width: 2) : null,
              ),
              child: Column(
                children: [
                  Icon(Icons.merge_type, size: 28,
                    color: !_overwrite ? DesignTokens.accent : DesignTokens.textAux1),
                  const SizedBox(height: DesignTokens.elementGap),
                  const Text('合并', style: TextStyle(
                    fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  )),
                  const SizedBox(height: 2),
                  const Text('保留目标已有课表\n仅添加新课程', style: TextStyle(
                    fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
                  ), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.cardGap),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _overwrite = true),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.cardPadding),
              decoration: BoxDecoration(
                color: DesignTokens.card,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                border: _overwrite ? Border.all(color: DesignTokens.accent, width: 2) : null,
              ),
              child: Column(
                children: [
                  Icon(Icons.delete_sweep, size: 28,
                    color: _overwrite ? DesignTokens.accent : DesignTokens.textAux1),
                  const SizedBox(height: DesignTokens.elementGap),
                  const Text('覆盖', style: TextStyle(
                    fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  )),
                  const SizedBox(height: 2),
                  const Text('清空目标对应天\n再复制全部课程', style: TextStyle(
                    fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
                  ), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(String semesterId) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final sourceSchedules = scheduleProvider.getSchedulesForStudent(_sourceStudent!.id, semesterId)
        .where((s) => _selectedDays.contains(s.dayOfWeek))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: DesignTokens.successBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 20, color: DesignTokens.successText),
              const SizedBox(width: DesignTokens.elementGap),
              Text('即将复制 ${sourceSchedules.length} 节课', style: const TextStyle(
                fontSize: DesignTokens.cardTitleSize,
                fontWeight: DesignTokens.cardTitleWeight,
                color: DesignTokens.successText,
              )),
            ],
          ),
          const SizedBox(height: DesignTokens.elementGap),
          Text('从「${_sourceStudent!.name}」→ 到「${_targetStudent!.name}」', style: const TextStyle(
            fontSize: DesignTokens.bodySize, color: DesignTokens.textSecondary,
          )),
          if (_overwrite) ...[
            const SizedBox(height: DesignTokens.elementGap),
            Text('⚠️ 将覆盖「${_targetStudent!.name}」在所选星期的全部课程', style: const TextStyle(
              fontSize: DesignTokens.auxSize, color: DesignTokens.pendingText,
            )),
          ],
        ],
      ),
    );
  }

  void _doCopy(String semesterId) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final sourceSchedules = scheduleProvider.getSchedulesForStudent(_sourceStudent!.id, semesterId)
        .where((s) => _selectedDays.contains(s.dayOfWeek))
        .toList();

    if (sourceSchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('源学生在所选日期没有课表')),
      );
      return;
    }

    // 覆盖模式：先删除目标学生在所选星期的课表
    if (_overwrite) {
      final targetSchedules = scheduleProvider.getSchedulesForStudent(_targetStudent!.id, semesterId)
          .where((s) => _selectedDays.contains(s.dayOfWeek))
          .toList();
      for (final s in targetSchedules) {
        scheduleProvider.deleteSchedule(s.id);
      }
    }

    // 复制课表
    int copied = 0;
    for (final source in sourceSchedules) {
      final newSchedule = CourseSchedule(
        id: 'schedule_${_targetStudent!.id}_${DateTime.now().millisecondsSinceEpoch}_$copied',
        studentId: _targetStudent!.id,
        semesterId: semesterId,
        dayOfWeek: source.dayOfWeek,
        period: source.period,
        subject: source.subject,
        classroom: source.classroom,
        weekType: source.weekType,
      );
      scheduleProvider.addSchedule(newSchedule);
      copied++;
    }

    // 显示成功提示
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.cardRadius)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 56, color: DesignTokens.accent),
            const SizedBox(height: DesignTokens.elementGapLarge),
            const Text('复制成功！', style: TextStyle(
              fontSize: DesignTokens.cardTitleSizeLarge,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            )),
            const SizedBox(height: DesignTokens.elementGap),
            Text('已复制 $copied 节课到「${_targetStudent!.name}」', style: const TextStyle(
              fontSize: DesignTokens.bodySize, color: DesignTokens.textSecondary,
            )),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: DesignTokens.textPrimary,
              ),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }
}
