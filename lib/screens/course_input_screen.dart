import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/models/course_schedule.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/utils/subject_colors.dart';
import 'package:course_manager/widgets/period_selector.dart';
import 'package:course_manager/widgets/day_selector.dart';
import 'package:course_manager/widgets/subject_selector.dart';

/// S3 课程录入/编辑页面
/// 支持新增和编辑模式：courseId != null 时为编辑模式，预填已有数据
/// 支持从课表空白格子点击自动填充星期和节次
class CourseInputScreen extends StatefulWidget {
  final String studentId;
  final String? courseId; // null=新增, 非null=编辑
  final int? initialDay;   // 从空白格子传入的初始星期(1-5)
  final int? initialPeriod; // 从空白格子传入的初始节次(0=早读,1-8=正式课)

  const CourseInputScreen({
    super.key,
    required this.studentId,
    this.courseId,
    this.initialDay,
    this.initialPeriod,
  });

  @override
  State<CourseInputScreen> createState() => _CourseInputScreenState();
}

class _CourseInputScreenState extends State<CourseInputScreen> {
  int _selectedPeriod = 1;
  int _selectedDay = 1;
  String _selectedSubject = '';
  final TextEditingController _classroomController = TextEditingController();
  String _weekType = 'ALL';
  bool _isEditing = false;
  CourseSchedule? _existingCourse;

  @override
  void initState() {
    super.initState();
    // 从空白格子点击传入的初始值（仅在新增模式且非编辑时生效）
    if (widget.courseId == null) {
      if (widget.initialDay != null) _selectedDay = widget.initialDay!;
      if (widget.initialPeriod != null) _selectedPeriod = widget.initialPeriod!;
    }
    if (widget.courseId != null) {
      _loadExistingCourse();
    }
  }

  void _loadExistingCourse() {
    final scheduleProvider = context.read<ScheduleProvider>();
    final course = scheduleProvider.schedules
        .where((s) => s.id == widget.courseId)
        .firstOrNull;
    if (course != null) {
      _existingCourse = course;
      _isEditing = true;
      _selectedPeriod = course.period;
      _selectedDay = course.dayOfWeek;
      _selectedSubject = course.subject;
      _classroomController.text = course.classroom;
      _weekType = course.weekType;
    }
  }

  @override
  void dispose() {
    _classroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, _) {
        final student = studentProvider.students
            .where((s) => s.id == widget.studentId)
            .firstOrNull;

        if (student == null) {
          return Scaffold(
            backgroundColor: DesignTokens.bg,
            appBar: AppBar(
              title: Text(_isEditing ? '编辑课程' : '添加课程'),
              backgroundColor: DesignTokens.bg,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('未找到学生信息')),
          );
        }

        final avatarColor = hexToColor(student.avatarColor);
        final initial = student.name.isNotEmpty ? student.name[0] : '?';

        return Scaffold(
          backgroundColor: DesignTokens.bg,
          appBar: AppBar(
            title: Text(_isEditing ? '编辑课程' : '添加课程'),
            backgroundColor: DesignTokens.bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // 编辑模式下显示删除按钮
            actions: _isEditing ? [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: DesignTokens.pendingText),
                onPressed: _deleteCourse,
                tooltip: '删除课程',
              ),
            ] : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.pageMargin,
              vertical: DesignTokens.elementGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentInfo(student, avatarColor, initial),
                const SizedBox(height: DesignTokens.cardGapLarge),

                PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                ),
                const SizedBox(height: DesignTokens.cardGapLarge),

                DaySelector(
                  selectedDay: _selectedDay,
                  onDayChanged: (d) => setState(() => _selectedDay = d),
                ),
                const SizedBox(height: DesignTokens.cardGapLarge),

                _buildSubjectSelector(),
                const SizedBox(height: DesignTokens.cardGapLarge),

                TextField(
                  controller: _classroomController,
                  decoration: const InputDecoration(
                    labelText: '教室',
                    hintText: '如：301教室',
                  ),
                ),
                const SizedBox(height: DesignTokens.cardGapLarge),

                _buildWeekTypeSelector(),
                const SizedBox(height: DesignTokens.cardGapLarge * 2),

                // 保存按钮
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.accent,
                    foregroundColor: DesignTokens.textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                    ),
                  ),
                  child: Text(_isEditing ? '保存修改' : '保存'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentInfo(Student student, Color avatarColor, String initial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('当前学生', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        Container(
          padding: const EdgeInsets.all(DesignTokens.cardPadding),
          decoration: BoxDecoration(
            color: DesignTokens.pillBg,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initial, style: const TextStyle(
                fontSize: DesignTokens.auxSizeLarge, fontWeight: FontWeight.w600, color: Colors.white,
              )),
            ),
            const SizedBox(width: DesignTokens.elementGapLarge),
            Expanded(child: Text('${student.name} · ${student.grade}${student.className}', style: const TextStyle(
              fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight, color: DesignTokens.textPrimary,
            ))),
          ]),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector() {
    final subjectColor = _selectedSubject.isNotEmpty
        ? getColorForSubject(_selectedSubject, widget.studentId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('科目', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        GestureDetector(
          onTap: () async {
            final result = await SubjectSelector.showSubjectSelector(context);
            if (result != null && result.isNotEmpty) {
              setState(() => _selectedSubject = result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.cardPadding, vertical: 12),
            decoration: BoxDecoration(
              color: subjectColor ?? DesignTokens.pillBg,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              border: subjectColor == null ? Border.all(color: DesignTokens.border) : null,
            ),
            child: Row(children: [
              if (_selectedSubject.isNotEmpty)
                Expanded(child: Text(_selectedSubject, style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight,
                  color: subjectColor != null ? Colors.white : DesignTokens.textPrimary,
                )))
              else
                const Expanded(child: Text('点击选择科目', style: TextStyle(
                  fontSize: DesignTokens.bodySize, color: DesignTokens.textAux2,
                ))),
              const Icon(Icons.chevron_right, size: 20, color: DesignTokens.textAux1),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekTypeSelector() {
    const options = ['A周', 'B周', '每周'];
    const values = ['A', 'B', 'ALL'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('单双周', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        Row(
          children: List.generate(3, (index) {
            final isSelected = _weekType == values[index];
            return GestureDetector(
              onTap: () => setState(() => _weekType = values[index]),
              child: Container(
                width: 80, height: 36,
                margin: const EdgeInsets.only(right: DesignTokens.elementGap),
                decoration: BoxDecoration(
                  color: isSelected ? DesignTokens.accent : DesignTokens.pillBg,
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                ),
                alignment: Alignment.center,
                child: Text(options[index], style: TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: isSelected ? FontWeight.w600 : DesignTokens.bodyWeight,
                  color: isSelected ? Colors.white : DesignTokens.textSecondary,
                )),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _save() {
    if (_selectedSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择科目')),
      );
      return;
    }

    final scheduleProvider = context.read<ScheduleProvider>();
    final semesterProvider = context.read<SemesterProvider>();
    final activeSemester = semesterProvider.activeSemester;

    if (activeSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建学期')),
      );
      return;
    }

    if (_isEditing && _existingCourse != null) {
      // 编辑模式：更新已有课程
      _existingCourse!.dayOfWeek = _selectedDay;
      _existingCourse!.period = _selectedPeriod;
      _existingCourse!.subject = _selectedSubject;
      _existingCourse!.classroom = _classroomController.text.trim();
      _existingCourse!.weekType = _weekType;
      scheduleProvider.updateSchedule(_existingCourse!);
    } else {
      // 新增模式
      final id = 'course_${DateTime.now().millisecondsSinceEpoch}';
      final schedule = CourseSchedule(
        id: id,
        studentId: widget.studentId,
        semesterId: activeSemester.id,
        dayOfWeek: _selectedDay,
        period: _selectedPeriod,
        subject: _selectedSubject,
        classroom: _classroomController.text.trim(),
        weekType: _weekType,
      );
      scheduleProvider.addSchedule(schedule);
    }

    Navigator.of(context).pop();
  }

  void _deleteCourse() {
    if (_existingCourse == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${_existingCourse!.subject}」这门课吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScheduleProvider>().deleteSchedule(_existingCourse!.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // 返回课表页
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.pendingText),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
