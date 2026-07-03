import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/onboarding_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/models/semester.dart';
import 'package:course_manager/widgets/onboarding_step.dart';

/// 新用户引导页面
/// 4步引导流程：欢迎 → 添加学生 → 选择学期 → 快速录入提示
/// 使用 Consumer<OnboardingProvider> 管理步骤

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Step 1 输入控制器
  final _studentNameController = TextEditingController();
  final _studentGradeController = TextEditingController();
  final _studentClassController = TextEditingController();

  // Step 2 输入控制器
  final _semesterNameController = TextEditingController();
  final _semesterSchoolController = TextEditingController();
  DateTime _semesterStartDate = DateTime.now();
  DateTime _semesterEndDate = DateTime.now().add(const Duration(days: 140));

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentGradeController.dispose();
    _studentClassController.dispose();
    _semesterNameController.dispose();
    _semesterSchoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onboarding, _) {
        final currentStep = onboarding.currentStep;

        return Scaffold(
          backgroundColor: DesignTokens.bg,
          body: SafeArea(
            child: Column(
              children: [
                // 内容区域
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStep(currentStep, onboarding),
                  ),
                ),

                // 进度指示器
                _ProgressIndicator(currentStep: currentStep),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建当前步骤
  Widget _buildStep(int step, OnboardingProvider onboarding) {
    switch (step) {
      case 0:
        return StepWelcome(
          key: const ValueKey(0),
          onNext: () => onboarding.nextStep(),
        );
      case 1:
        return StepAddStudent(
          key: const ValueKey(1),
          onNext: _saveStudentAndNext,
          onSkip: () => onboarding.nextStep(),
          nameController: _studentNameController,
          gradeController: _studentGradeController,
          classController: _studentClassController,
        );
      case 2:
        return StepAddSemester(
          key: const ValueKey(2),
          onNext: _saveSemesterAndNext,
          onSkip: () => onboarding.nextStep(),
          nameController: _semesterNameController,
          schoolController: _semesterSchoolController,
          startDate: _semesterStartDate,
          endDate: _semesterEndDate,
          onStartDateChanged: (d) => setState(() => _semesterStartDate = d),
          onEndDateChanged: (d) => setState(() => _semesterEndDate = d),
        );
      case 3:
        return StepReady(
          key: const ValueKey(3),
          onStartSchedule: _completeAndGoSchedule,
          onSkipToHome: _completeAndGoHome,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 保存学生并进入下一步
  void _saveStudentAndNext() {
    final name = _studentNameController.text.trim();
    if (name.isEmpty) return;

    final student = Student(
      id: 'student_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      grade: _studentGradeController.text.trim(),
      className: _studentClassController.text.trim(),
    );

    context.read<StudentProvider>().addStudent(student);
    context.read<OnboardingProvider>().nextStep();
  }

  /// 保存学期并进入下一步
  void _saveSemesterAndNext() {
    final name = _semesterNameController.text.trim();
    if (name.isEmpty) return;

    final semester = Semester(
      id: 'semester_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      schoolName: _semesterSchoolController.text.trim(),
      startDate: _semesterStartDate,
      endDate: _semesterEndDate,
      totalWeeks: (_semesterEndDate.difference(_semesterStartDate).inDays / 7).ceil(),
      isActive: true,
    );

    context.read<SemesterProvider>().addSemester(semester);
    context.read<OnboardingProvider>().nextStep();
  }

  /// 完成引导并跳转到课表
  void _completeAndGoSchedule() {
    context.read<OnboardingProvider>().completeOnboarding();
    GoRouter.of(context).go('/tabs/schedule');
  }

  /// 完成引导并跳转到主页
  void _completeAndGoHome() {
    context.read<OnboardingProvider>().completeOnboarding();
    GoRouter.of(context).go('/tabs/schedule');
  }
}

/// 进度指示器（4个圆点）
class _ProgressIndicator extends StatelessWidget {
  final int currentStep;

  const _ProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: DesignTokens.cardGapLarge * 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(OnboardingProvider.totalSteps, (index) {
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isCurrent ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? DesignTokens.accent
                  : DesignTokens.textAux3.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
