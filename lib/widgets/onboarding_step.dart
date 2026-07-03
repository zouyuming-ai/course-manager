import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';

/// 引导步骤组件工厂
/// 提供4个步骤 widget：StepWelcome、StepAddStudent、StepAddSemester、StepReady

// ===== Step 0: 欢迎页 =====

class StepWelcome extends StatelessWidget {
  final VoidCallback onNext;

  const StepWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.pageMargin * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo 区域
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DesignTokens.pillBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.backpack,
              size: 50,
              color: DesignTokens.accent,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 标题
          const Text(
            '课程小管家',
            style: TextStyle(
              fontSize: DesignTokens.heroSize,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          // 副标题
          const Text(
            '让每个书包都准备就绪',
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge * 2),

          // 开始按钮
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: DesignTokens.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadiusLarge,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '开始',
                style: TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Step 1: 添加学生 =====

class StepAddStudent extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  final TextEditingController nameController;
  final TextEditingController gradeController;
  final TextEditingController classController;

  const StepAddStudent({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.nameController,
    required this.gradeController,
    required this.classController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.pageMargin,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '添加孩子信息',
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSizeLarge,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),
          const Text(
            '输入孩子的姓名、年级和班级',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 姓名输入
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: '孩子姓名',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 年级输入
          TextField(
            controller: gradeController,
            decoration: const InputDecoration(
              hintText: '年级（如：一年级）',
              prefixIcon: Icon(Icons.grade_outlined, size: 20),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 班级输入
          TextField(
            controller: classController,
            decoration: const InputDecoration(
              hintText: '班级（如：1班）',
              prefixIcon: Icon(Icons.class_outlined, size: 20),
            ),
          ),

          const SizedBox(height: DesignTokens.cardGapLarge * 2),

          // 底部导航按钮
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text('跳过'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onNext,
                child: const Text('下一步'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Step 2: 选择学期 =====

class StepAddSemester extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  final TextEditingController nameController;
  final TextEditingController schoolController;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const StepAddSemester({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.nameController,
    required this.schoolController,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.pageMargin,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置学期',
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSizeLarge,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),
          const Text(
            '输入学期名称和起止日期',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 学期名称输入
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: '学期名称（如：2026春季学期）',
              prefixIcon: Icon(Icons.school_outlined, size: 20),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 学校名称输入
          TextField(
            controller: schoolController,
            decoration: const InputDecoration(
              hintText: '学校名称',
              prefixIcon: Icon(Icons.home_work_outlined, size: 20),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 起始日期选择
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onStartDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.cardPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bg,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                border: Border.all(color: DesignTokens.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: DesignTokens.textSecondary),
                  const SizedBox(width: DesignTokens.elementGap),
                  Text(
                    '起始：${_formatDate(startDate)}',
                    style: const TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: DesignTokens.bodyWeight,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 结束日期选择
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: DateTime(2030),
              );
              if (picked != null) onEndDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.cardPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bg,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                border: Border.all(color: DesignTokens.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: DesignTokens.textSecondary),
                  const SizedBox(width: DesignTokens.elementGap),
                  Text(
                    '结束：${_formatDate(endDate)}',
                    style: const TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: DesignTokens.bodyWeight,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.cardGapLarge * 2),

          // 底部导航按钮
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text('跳过'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onNext,
                child: const Text('下一步'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';
}

// ===== Step 3: 快速录入提示 =====

class StepReady extends StatelessWidget {
  final VoidCallback onStartSchedule;
  final VoidCallback onSkipToHome;

  const StepReady({
    super.key,
    required this.onStartSchedule,
    required this.onSkipToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.pageMargin * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 完成图标
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: DesignTokens.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: DesignTokens.successText,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          const Text(
            '设置完成！',
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSizeLarge,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          const Text(
            '你可以开始录入课表了',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge * 2),

          // 开始录入按钮
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: onStartSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: DesignTokens.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadiusLarge,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '开始录入',
                style: TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          // 稍后录入按钮
          TextButton(
            onPressed: onSkipToHome,
            child: const Text(
              '稍后录入',
              style: TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: DesignTokens.bodyWeight,
                color: DesignTokens.textAux1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
