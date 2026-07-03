import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/backpack_provider.dart';
import 'package:course_manager/providers/reminder_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/providers/theme_provider.dart';
import 'package:course_manager/models/backpack_item.dart';
import 'package:course_manager/models/reminder.dart';
import 'package:course_manager/widgets/backpack_item_row.dart';
import 'package:course_manager/screens/empty_state.dart';
import 'package:course_manager/dialogs/add_reminder_dialog.dart';

/// S8 书包准备页面（书包Tab首页）
/// 包含书包准备清单 + 提醒列表两部分
/// 修复：提醒区域始终可见，不依赖书包物品是否为空

class BackpackScreen extends StatelessWidget {
  const BackpackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final backpackProvider = context.watch<BackpackProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    final semesterProvider = context.read<SemesterProvider>();

    final bgColor = themeProvider.bgColor;

    final activeStudent = studentProvider.activeStudent;

    // 无活跃学生时显示空状态
    if (activeStudent == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('书包准备')),
        body: const BackpackEmptyState(),
      );
    }

    // 自动生成明天的书包建议（基于课表）
    final activeSemester = semesterProvider.activeSemester;
    if (activeSemester != null) {
      backpackProvider.generateSuggestionsForTomorrow(
        activeStudent.id,
        activeSemester.id,
        scheduleProvider.schedules,
      );
    }

    // 获取明天的书包物品
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDayOfWeek = tomorrow.weekday; // 1=周一
    final backpackItems = backpackProvider.getItemsForDay(
      activeStudent.id,
      tomorrowDayOfWeek,
      tomorrow,
    );

    // 获取所有提醒（含已完成）
    final pendingReminders = reminderProvider.getPendingReminders(activeStudent.id);
    final completedReminders = reminderProvider.getCompletedReminders(activeStudent.id);

    // 分组待完成提醒：今天 / 明天 / 未来
    final today = DateTime.now();
    final todayReminders = pendingReminders.where((r) =>
      r.reminderDate.year == today.year &&
      r.reminderDate.month == today.month &&
      r.reminderDate.day == today.day
    ).toList();

    final tomorrowReminders = pendingReminders.where((r) =>
      r.reminderDate.year == tomorrow.year &&
      r.reminderDate.month == tomorrow.month &&
      r.reminderDate.day == tomorrow.day
    ).toList();

    final futureReminders = pendingReminders.where((r) =>
      r.reminderDate.isAfter(tomorrow)
    ).toList();

    final hasReminders = pendingReminders.isNotEmpty || completedReminders.isNotEmpty;

    // 已装入数量
    final packedCount = backpackItems.where((i) => i.isPacked).length;
    final totalCount = backpackItems.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('书包准备'),
        actions: [
          // 添加提醒按钮
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AddReminderDialog(
                  studentId: activeStudent.id,
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
          // 查看全部提醒按钮（有提醒时始终显示）
          IconButton(
            onPressed: () {
              context.push('/reminders');
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '查看全部提醒',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.cardGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 第一区域：书包准备清单 =====
            if (backpackItems.isEmpty)
              // 空书包提示（可手动添加）
              _buildEmptyBackpackCard(context, activeStudent.id)
            else
              _buildBackpackCard(backpackItems, packedCount, totalCount, activeStudent.id),

            // ===== 第二区域：提醒列表（始终可见） =====
            if (hasReminders)
              _buildRemindersSection(context, todayReminders, tomorrowReminders, futureReminders, completedReminders),
          ],
        ),
      ),
    );
  }

  /// 空书包提示卡片（鼓励用户添加物品或先录入课表）
  Widget _buildEmptyBackpackCard(BuildContext context, String studentId) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.backpack_outlined,
                size: 22,
                color: DesignTokens.textPrimary,
              ),
              const SizedBox(width: DesignTokens.elementGap),
              const Text(
                '明天的书包',
                style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize,
                  fontWeight: DesignTokens.cardTitleWeight,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),
          const Text(
            '还没有书包准备物品',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),
          const Text(
            '录入课表后，系统会根据明天课程自动生成书包清单，你也可以手动添加。',
            style: TextStyle(
              fontSize: DesignTokens.auxSize,
              color: DesignTokens.textAux1,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),
          // 手动添加物品按钮
          GestureDetector(
            onTap: () => _showAddItemDialog(context, studentId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: DesignTokens.pillBg,
                borderRadius: BorderRadius.circular(
                  DesignTokens.buttonRadiusLarge,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: DesignTokens.textSecondary,
                  ),
                  SizedBox(width: DesignTokens.elementGap / 2),
                  Text(
                    '手动添加物品',
                    style: TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: DesignTokens.bodyWeight,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 有物品的书包卡片
  Widget _buildBackpackCard(List<BackpackItem> backpackItems, int packedCount, int totalCount, String studentId) {
    return Builder(
      builder: (context) {
        final accentColor = context.watch<ThemeProvider>().accentColor;
        return Container(
          decoration: BoxDecoration(
            color: DesignTokens.card,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          padding: const EdgeInsets.all(DesignTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  const Icon(Icons.backpack_outlined, size: 22, color: DesignTokens.textPrimary),
                  const SizedBox(width: DesignTokens.elementGap),
                  const Text('明天的书包', style: TextStyle(
                    fontSize: DesignTokens.cardTitleSize,
                    fontWeight: DesignTokens.cardTitleWeight,
                    color: DesignTokens.textPrimary,
                  )),
                  const Spacer(),
                  Text('$packedCount/$totalCount 已准备', style: const TextStyle(
                    fontSize: DesignTokens.auxSize,
                    fontWeight: DesignTokens.auxWeight,
                    color: DesignTokens.textSecondary,
                  )),
                ],
              ),
              const SizedBox(height: DesignTokens.elementGapLarge),

              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? packedCount / totalCount : 0,
                  backgroundColor: DesignTokens.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: DesignTokens.elementGapLarge),

              // 物品列表
              ...backpackItems.map((item) => BackpackItemRow(
                item: item,
                onTogglePacked: () {
                  context.read<BackpackProvider>().togglePacked(item.id);
                },
                onDelete: () {
                  context.read<BackpackProvider>().deleteItem(item.id);
                },
              )),

              // 手动添加物品按钮
              const SizedBox(height: DesignTokens.elementGapLarge),
              GestureDetector(
                onTap: () => _showAddItemDialog(context, studentId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: DesignTokens.pillBg,
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: DesignTokens.textSecondary),
                      SizedBox(width: DesignTokens.elementGap / 2),
                      Text('手动添加物品', style: TextStyle(
                        fontSize: DesignTokens.bodySize,
                        fontWeight: DesignTokens.bodyWeight,
                        color: DesignTokens.textSecondary,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 提醒区域（始终可见，含已完成）
  Widget _buildRemindersSection(BuildContext context, List<Reminder> todayReminders, List<Reminder> tomorrowReminders, List<Reminder> futureReminders, List<Reminder> completedReminders) {
    final accentColor = context.watch<ThemeProvider>().accentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.cardGapLarge),

        // 提醒标题行
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 20, color: accentColor),
            const SizedBox(width: DesignTokens.elementGap),
            const Text('提醒', style: TextStyle(
              fontSize: DesignTokens.cardTitleSize,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            )),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/reminders'),
              child: Text('查看全部', style: TextStyle(
                fontSize: DesignTokens.auxSize,
                color: accentColor,
              )),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.cardGap),

        // 待完成提醒
        if (todayReminders.isNotEmpty) ...[
          _buildSectionLabel('今天'),
          ...todayReminders.take(3).map((r) => _ReminderCard(
            reminder: r,
            onToggleComplete: () => context.read<ReminderProvider>().toggleComplete(r.id),
            onEdit: () => _showEditReminderDialog(context, r),
          )),
        ],
        if (tomorrowReminders.isNotEmpty) ...[
          _buildSectionLabel('明天'),
          ...tomorrowReminders.take(3).map((r) => _ReminderCard(
            reminder: r,
            onToggleComplete: () => context.read<ReminderProvider>().toggleComplete(r.id),
            onEdit: () => _showEditReminderDialog(context, r),
          )),
        ],
        if (futureReminders.isNotEmpty) ...[
          _buildSectionLabel('稍后'),
          ...futureReminders.take(2).map((r) => _ReminderCard(
            reminder: r,
            onToggleComplete: () => context.read<ReminderProvider>().toggleComplete(r.id),
            onEdit: () => _showEditReminderDialog(context, r),
          )),
        ],

        // 已完成提醒（可恢复，最多展示3条）
        if (completedReminders.isNotEmpty) ...[
          _buildSectionLabel('已完成'),
          ...completedReminders.take(3).map((r) => _ReminderCard(
            reminder: r,
            onToggleComplete: () => context.read<ReminderProvider>().toggleComplete(r.id),
            onEdit: () => _showEditReminderDialog(context, r),
          )),
          if (completedReminders.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.elementGap),
              child: Center(
                child: Text('还有${completedReminders.length - 3}条已完成提醒，点击"查看全部"', style: const TextStyle(
                  fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
                )),
              ),
            ),
        ],
      ],
    );
  }

  /// 分组标签
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.elementGap, top: DesignTokens.elementGap),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: DesignTokens.auxSize,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textSecondary,
        ),
      ),
    );
  }

  /// 手动添加书包物品对话框
  void _showAddItemDialog(BuildContext context, String studentId) {
    final itemNameController = TextEditingController();
    final subjectController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: DesignTokens.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.cardRadiusLarge),
            ),
          ),
          padding: const EdgeInsets.all(DesignTokens.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加书包物品', style: TextStyle(
                fontSize: DesignTokens.cardTitleSize,
                fontWeight: DesignTokens.cardTitleWeight,
                color: DesignTokens.textPrimary,
              )),
              const SizedBox(height: DesignTokens.elementGapLarge),
              TextField(
                controller: itemNameController,
                decoration: const InputDecoration(hintText: '物品名称'),
              ),
              const SizedBox(height: DesignTokens.elementGap),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(hintText: '关联科目（可选）'),
              ),
              const SizedBox(height: DesignTokens.elementGapLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (itemNameController.text.trim().isEmpty) return;
                    final item = BackpackItem(
                      id: 'manual_${studentId}_${DateTime.now().millisecondsSinceEpoch}',
                      studentId: studentId,
                      itemName: itemNameController.text.trim(),
                      relatedSubject: subjectController.text.trim(),
                      relatedDayOfWeek: DateTime.now().add(const Duration(days: 1)).weekday,
                      isRecurring: false,
                      specificDate: DateTime.now().add(const Duration(days: 1)),
                      isPacked: false,
                      isAutoGenerated: false,
                    );
                    context.read<BackpackProvider>().addManualItem(item);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 编辑提醒对话框
  void _showEditReminderDialog(BuildContext context, Reminder reminder) {
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

/// 提醒卡片组件
class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggleComplete;
  final VoidCallback? onEdit; // 编辑回调

  const _ReminderCard({
    required this.reminder,
    required this.onToggleComplete,
    this.onEdit,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '表单': return Icons.description_outlined;
      case '物品': return Icons.inventory_2_outlined;
      case '活动': return Icons.emoji_events_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getCategoryColor(String category, Color accentColor) {
    switch (category) {
      case '表单': return DesignTokens.pendingText;
      case '物品': return accentColor;
      case '活动': return DesignTokens.subjectColors['唱游'] ?? DesignTokens.textAux1;
      default: return DesignTokens.textAux1;
    }
  }

  /// 判断提醒是否已到时间或过期（未完成且提醒时间已过）
  bool _isReminderOverdue(Reminder r) {
    if (r.isCompleted) return false;
    final timeParts = r.reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    final deadline = DateTime(
      r.reminderDate.year, r.reminderDate.month, r.reminderDate.day,
      hour, minute,
    );
    return DateTime.now().isAfter(deadline);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = reminder.isCompleted;
    final isOverdue = _isReminderOverdue(reminder);
    final accentColor = context.watch<ThemeProvider>().accentColor;
    final categoryColor = _getCategoryColor(reminder.category, accentColor);

    // 过期或已完成的状态颜色
    Color statusColor;
    Color statusTextColor;
    String? statusLabel;
    if (isCompleted) {
      statusColor = DesignTokens.successBg;
      statusTextColor = DesignTokens.successText;
      statusLabel = '已完成';
    } else if (isOverdue) {
      statusColor = const Color(0xFFFFF3E0);  // 淡橙底
      statusTextColor = const Color(0xFFE65100);  // 深橙字
      statusLabel = '已到时间';
    } else {
      statusColor = categoryColor.withValues(alpha: 0.15);
      statusTextColor = categoryColor;
      statusLabel = null;
    }

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(reminder.category),
              size: 20,
              color: statusTextColor,
            ),
          ),
          const SizedBox(width: DesignTokens.elementGapLarge),
          // 内容区 — 点击进入编辑
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.content,
                    style: TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: DesignTokens.bodyWeight,
                      color: isCompleted ? DesignTokens.textAux1 : DesignTokens.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_formatDate(reminder.reminderDate)} ${reminder.reminderTime}',
                        style: const TextStyle(
                          fontSize: DesignTokens.auxSize,
                          fontWeight: DesignTokens.auxWeight,
                          color: DesignTokens.textAux1,
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(width: DesignTokens.elementGap),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: DesignTokens.tagSize,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 完成勾选
          GestureDetector(
            onTap: onToggleComplete,
            behavior: HitTestBehavior.opaque,
            child: isCompleted
                ? Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 16, color: DesignTokens.card),
                  )
                : Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: DesignTokens.textAux3, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          // 编辑按钮
          if (onEdit != null) ...[
            const SizedBox(width: DesignTokens.elementGap),
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.edit_outlined, size: 16, color: DesignTokens.textAux1),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}月${date.day}日';
}
