import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

/// 提醒摘要卡片 — 课表网格上方，显示明天提醒摘要
/// 动态使用 ThemeProvider accentColor

class ReminderSummaryCard extends StatelessWidget {
  final List<String> reminderTexts;
  final VoidCallback? onTap;

  const ReminderSummaryCard({
    super.key,
    required this.reminderTexts,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reminderTexts.isEmpty) {
      return const SizedBox.shrink();
    }

    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final summaryText = reminderTexts.join('；');

    return GestureDetector(
      onTap: onTap ?? () => context.go('/tabs/backpack'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.elementGap,
        ),
        padding: const EdgeInsets.all(DesignTokens.cardPadding),
        decoration: BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.textPrimary.withValues(alpha: 0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              child: Icon(
                Icons.backpack_outlined,
                size: 20,
                color: accentColor,
              ),
            ),
            const SizedBox(width: DesignTokens.elementGapLarge),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '明天提醒',
                    style: TextStyle(
                      fontSize: DesignTokens.auxSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summaryText,
                    style: const TextStyle(
                      fontSize: DesignTokens.auxSize,
                      fontWeight: DesignTokens.auxWeight,
                      color: DesignTokens.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 20,
              color: DesignTokens.textAux2,
            ),
          ],
        ),
      ),
    );
  }
}
