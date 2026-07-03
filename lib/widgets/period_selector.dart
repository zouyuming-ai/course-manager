import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';

/// 节次选择器组件
/// 设计规格：水平排列9个圆角按钮(早读 + 第1节~第8节)
/// 选中：#FFC857填充+白色文字, 未选中：#F5EED4填充+#5C5147文字
/// 圆角14px, 间距8px
class PeriodSelector extends StatelessWidget {
  /// 当前选中的节次 (0=早读, 1-8=第1~8节)
  final int selectedPeriod;

  /// 选择回调
  final ValueChanged<int> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  /// 节次标签：早读 + 第1节 ~ 第8节（共9个）
  static const List<String> _labels = [
    '早读', '第1节', '第2节', '第3节', '第4节',
    '第5节', '第6节', '第7节', '第8节',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '节次',
          style: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.elementGap),
        // 第一行：早读~第4节
        _buildRow(0, 5),
        const SizedBox(height: DesignTokens.elementGap),
        // 第二行：第5节~第8节
        _buildRow(5, 4),
      ],
    );
  }

  Widget _buildRow(int start, int count) {
    return Row(
      children: List.generate(count, (index) {
        final period = start + index;
        final isSelected = period == selectedPeriod;

        return GestureDetector(
          onTap: () => onPeriodChanged(period),
          child: Container(
            width: period == 0 ? 44 : 50,
            height: 36,
            margin: const EdgeInsets.only(right: DesignTokens.elementGap),
            decoration: BoxDecoration(
              color: isSelected ? DesignTokens.accent : DesignTokens.pillBg,
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
            ),
            alignment: Alignment.center,
            child: Text(
              _labels[period],
              style: TextStyle(
                fontSize: period == 0 ? DesignTokens.auxSize : DesignTokens.auxSize,
                fontWeight: isSelected ? FontWeight.w600 : DesignTokens.bodyWeight,
                color: isSelected ? Colors.white : DesignTokens.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
