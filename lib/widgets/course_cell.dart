import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/models/course_schedule.dart';

/// 课程格子组件 — 课表网格中的单个课程卡片
/// 设计规格：正方形，科目颜色背景，科目名+教室名自适应缩放

class CourseCell extends StatelessWidget {
  /// 课程数据（null 表示空课）
  final CourseSchedule? course;

  /// 科目颜色（从 SubjectColors 或 DesignTokens.subjectColors 获取）
  final Color? subjectColor;

  /// 点击回调
  final VoidCallback? onTap;

  const CourseCell({
    super.key,
    this.course,
    this.subjectColor,
    this.onTap,
  });

  /// 判断科目颜色是否为浅色（需要深色文字）
  static bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  @override
  Widget build(BuildContext context) {
    // 空课格子：保持正方形，方便与有课格子对齐
    if (course == null) {
      return GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              border: Border.all(
                color: DesignTokens.border,
                width: 1,
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    final color = subjectColor ?? DesignTokens.subjectColors[course!.subject] ?? DesignTokens.textSecondary;
    final isLight = _isLightColor(color);
    final textColor = isLight ? DesignTokens.textPrimary : DesignTokens.card;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 科目名：自适应缩放，确保在窄格子中也能显示
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  course!.subject,
                  style: TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              // 教室名（有值才显示）
              if (course!.classroom.isNotEmpty) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    course!.classroom,
                    style: TextStyle(
                      fontSize: DesignTokens.auxSize,
                      fontWeight: DesignTokens.auxWeight,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
