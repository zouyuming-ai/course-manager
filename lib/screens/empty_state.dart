import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 通用空状态组件
/// 用于各页面在无数据时展示引导性空状态

class EmptyState extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标题
  final String title;

  /// 副标题/说明
  final String subtitle;

  /// 操作按钮文字
  final String? actionText;

  /// 操作按钮回调
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 大图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DesignTokens.pillBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: DesignTokens.textAux1,
              ),
            ),
            const SizedBox(height: DesignTokens.elementGapLarge),

            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.cardTitleSize,
                fontWeight: DesignTokens.cardTitleWeight,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.elementGap),

            // 说明
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: DesignTokens.bodyWeight,
                color: DesignTokens.textSecondary,
              ),
            ),

            // 操作按钮（可选）
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.elementGapLarge),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.accent,
                  foregroundColor: DesignTokens.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 预置的空状态配置

/// 课表空状态
class ScheduleEmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const ScheduleEmptyState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_view_week_outlined,
      title: '还没有课表',
      subtitle: '添加孩子的课表，轻松管理每周课程',
      actionText: '添加课表',
      onAction: onAdd,
    );
  }
}

/// 书包空状态
class BackpackEmptyState extends StatelessWidget {
  final VoidCallback? onCheck;
  const BackpackEmptyState({super.key, this.onCheck});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.backpack_outlined,
      title: '书包是空的',
      subtitle: '根据明天的课表，自动生成书包清单',
      actionText: '查看明天课表',
      onAction: onCheck,
    );
  }
}

/// 学生空状态
class StudentsEmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const StudentsEmptyState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.people_outline,
      title: '还没有添加孩子',
      subtitle: '添加孩子的信息，开始管理课表',
      actionText: '添加孩子',
      onAction: onAdd,
    );
  }
}

/// 提醒空状态
class ReminderEmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const ReminderEmptyState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.notifications_outlined,
      title: '暂无提醒',
      subtitle: '添加提醒事项，不错过重要安排',
      actionText: '添加提醒',
      onAction: onAdd,
    );
  }
}
