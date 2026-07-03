import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';

/// 星期选择器组件
/// 设计规格：水平排列5个圆角按钮(周一~周五)
/// 选中：#FFC857填充+白色文字, 未选中：#F5EED4填充+#5C5147文字
/// 圆角14px, 间距8px
class DaySelector extends StatelessWidget {
  /// 当前选中的星期 (1-5 对应周一到周五)
  final int selectedDay;

  /// 选择回调
  final ValueChanged<int> onDayChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDayChanged,
  });

  /// 星期标签
  static const List<String> _labels = [
    '周一', '周二', '周三', '周四', '周五',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '星期',
          style: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.elementGap),
        Row(
          children: List.generate(5, (index) {
            final day = index + 1;
            final isSelected = day == selectedDay;

            return GestureDetector(
              onTap: () => onDayChanged(day),
              child: Container(
                width: 56,
                height: 36,
                margin: const EdgeInsets.only(
                  right: DesignTokens.elementGap,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? DesignTokens.accent : DesignTokens.pillBg,
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: isSelected ? FontWeight.w600 : DesignTokens.bodyWeight,
                    color: isSelected ? Colors.white : DesignTokens.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
