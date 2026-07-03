import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/reminder_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/models/reminder.dart';
import 'package:course_manager/screens/empty_state.dart';
import 'package:course_manager/dialogs/add_reminder_dialog.dart';

/// S7 提醒管理页面
/// 包含"待完成"和"已完成"两个分组，已完成可点击恢复
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final activeStudent = studentProvider.activeStudent;

    if (activeStudent == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bg,
        appBar: AppBar(title: const Text('提醒')),
        body: const ReminderEmptyState(),
      );
    }

    final pendingReminders = reminderProvider.getPendingReminders(activeStudent.id);
    final completedReminders = reminderProvider.getCompletedReminders(activeStudent.id);

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    // 分组待完成提醒
    final todayPending = pendingReminders.where((r) =>
      r.reminderDate.year == today.year && r.reminderDate.month == today.month && r.reminderDate.day == today.day
    ).toList();
    final tomorrowPending = pendingReminders.where((r) =>
      r.reminderDate.year == tomorrow.year && r.reminderDate.month == tomorrow.month && r.reminderDate.day == tomorrow.day
    ).toList();
    final weekPending = pendingReminders.where((r) =>
      r.reminderDate.isAfter(tomorrow) && r.reminderDate.isBefore(weekEnd)
    ).toList();

    final hasPending = todayPending.isNotEmpty || tomorrowPending.isNotEmpty || weekPending.isNotEmpty;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('提醒'),
        actions: [
          // 已完成切换按钮
          if (completedReminders.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _showCompleted = !_showCompleted),
              child: Text(
                _showCompleted ? '待完成(${pendingReminders.length})' : '已完成(${completedReminders.length})',
                style: const TextStyle(fontSize: DesignTokens.auxSize, color: DesignTokens.accent),
              ),
            ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AddReminderDialog(studentId: activeStudent.id),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _showCompleted
          ? _buildCompletedList(context, completedReminders)
          : !hasPending
              ? const ReminderEmptyState()
              : _buildPendingList(context, todayPending, tomorrowPending, weekPending),
    );
  }

  Widget _buildPendingList(BuildContext context, List<Reminder> today, List<Reminder> tomorrow, List<Reminder> week) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (today.isNotEmpty) ...[
            _buildSectionTitle('今天'),
            ...today.map((r) => _ReminderListCard(
              reminder: r,
              onToggle: () => context.read<ReminderProvider>().toggleComplete(r.id),
              onDelete: () => context.read<ReminderProvider>().deleteReminder(r.id),
              onEdit: () => _showEditReminder(context, r),
            )),
            const SizedBox(height: DesignTokens.cardGapLarge),
          ],
          if (tomorrow.isNotEmpty) ...[
            _buildSectionTitle('明天'),
            ...tomorrow.map((r) => _ReminderListCard(
              reminder: r,
              onToggle: () => context.read<ReminderProvider>().toggleComplete(r.id),
              onDelete: () => context.read<ReminderProvider>().deleteReminder(r.id),
              onEdit: () => _showEditReminder(context, r),
            )),
            const SizedBox(height: DesignTokens.cardGapLarge),
          ],
          if (week.isNotEmpty) ...[
            _buildSectionTitle('本周'),
            ...week.map((r) => _ReminderListCard(
              reminder: r,
              onToggle: () => context.read<ReminderProvider>().toggleComplete(r.id),
              onDelete: () => context.read<ReminderProvider>().deleteReminder(r.id),
              onEdit: () => _showEditReminder(context, r),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedList(BuildContext context, List<Reminder> completed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('已完成的提醒'),
          const SizedBox(height: DesignTokens.elementGap),
          const Text('点击圆圈可恢复为待完成', style: TextStyle(
            fontSize: DesignTokens.auxSize, color: DesignTokens.textAux2,
          )),
          const SizedBox(height: DesignTokens.cardGap),
          ...completed.map((r) => _ReminderListCard(
            reminder: r,
            onToggle: () => context.read<ReminderProvider>().toggleComplete(r.id), // 恢复为待完成
            onDelete: () => context.read<ReminderProvider>().deleteReminder(r.id),
            onEdit: () => _showEditReminder(context, r),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.elementGapLarge),
      child: Text(title, style: const TextStyle(
        fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight, color: DesignTokens.textPrimary,
      )),
    );
  }

  /// 编辑提醒
  void _showEditReminder(BuildContext context, Reminder reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddReminderDialog(
        studentId: reminder.studentId,
        editingReminder: reminder,
      ),
    );
  }
}

/// 提醒列表卡片
class _ReminderListCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit; // 编辑回调

  const _ReminderListCard({required this.reminder, required this.onToggle, required this.onDelete, this.onEdit});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '表单': return Icons.description_outlined;
      case '物品': return Icons.inventory_2_outlined;
      case '活动': return Icons.emoji_events_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '表单': return DesignTokens.pendingText;
      case '物品': return DesignTokens.accent;
      case '活动': return DesignTokens.subjectColors['唱游'] ?? DesignTokens.textAux1;
      default: return DesignTokens.textAux1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = reminder.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.cardGap),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _getCategoryColor(reminder.category).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getCategoryIcon(reminder.category), size: 20, color: _getCategoryColor(reminder.category)),
          ),
          const SizedBox(width: DesignTokens.elementGapLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.content, style: TextStyle(
                  fontSize: DesignTokens.bodySize, fontWeight: DesignTokens.bodyWeight,
                  color: isCompleted ? DesignTokens.textAux1 : DesignTokens.textPrimary,
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                )),
                const SizedBox(height: 4),
                Text('${_formatDate(reminder.reminderDate)} ${reminder.reminderTime}', style: const TextStyle(
                  fontSize: DesignTokens.auxSize, fontWeight: DesignTokens.auxWeight, color: DesignTokens.textAux1,
                )),
              ],
            ),
          ),
          // 完成勾选（点击可恢复）
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: isCompleted
                ? Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: DesignTokens.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 16, color: DesignTokens.card),
                  )
                : Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(border: Border.all(color: DesignTokens.textAux3, width: 2), shape: BoxShape.circle),
                  ),
          ),
          // 编辑按钮
          if (onEdit != null) ...[
            const SizedBox(width: DesignTokens.elementGap),
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.edit_outlined, size: 18, color: DesignTokens.textAux1),
            ),
          ],
          const SizedBox(width: DesignTokens.elementGap),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.close, size: 18, color: DesignTokens.textAux3),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}月${date.day}日';
}
