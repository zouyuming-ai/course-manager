import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/homework_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/models/homework.dart';
import 'package:course_manager/dialogs/add_homework_dialog.dart';

/// S19 家庭作业页面 — 两级结构
/// 第一级：按（科目 + 截止日期）分组展示
/// 第二级：每组内的多个任务，支持单独完成/恢复
class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final homeworkProvider = context.watch<HomeworkProvider>();
    final activeStudent = studentProvider.activeStudent;

    if (activeStudent == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bg,
        appBar: AppBar(title: const Text('家庭作业')),
        body: const Center(child: Text('请先选择学生')),
      );
    }

    final groupedPending = homeworkProvider.getGroupedPendingHomework(activeStudent.id);
    final groupedCompleted = homeworkProvider.getGroupedCompletedHomework(activeStudent.id);
    final totalPending = groupedPending.values.fold<int>(0, (sum, list) => sum + list.length);
    final totalCompleted = groupedCompleted.values.fold<int>(0, (sum, list) => sum + list.length);

    // 已完成列表清空时自动切回待完成视图
    if (_showCompleted && totalCompleted == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showCompleted = false);
      });
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(_showCompleted ? '已完成作业' : '家庭作业'),
        leading: _showCompleted
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showCompleted = false),
              )
            : null,
        actions: [
          // 已完成切换按钮：待完成模式时显示"已完成(N)"，已完成模式时显示"待完成(N)"
          if (!_showCompleted && totalCompleted > 0)
            TextButton(
              onPressed: () => setState(() => _showCompleted = true),
              child: Text(
                '已完成($totalCompleted)',
                style: const TextStyle(fontSize: DesignTokens.auxSize, color: DesignTokens.accent),
              ),
            ),
          if (_showCompleted)
            TextButton(
              onPressed: () => setState(() => _showCompleted = false),
              child: Text(
                '待完成($totalPending)',
                style: const TextStyle(fontSize: DesignTokens.auxSize, color: DesignTokens.accent),
              ),
            ),
          if (!_showCompleted)
            IconButton(
              onPressed: () => _addHomework(activeStudent.id),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: _showCompleted
          ? _buildCompletedView(groupedCompleted, totalCompleted)
          : _buildPendingView(groupedPending, activeStudent.id, totalPending),
    );
  }

  /// 待完成视图 —— 按科目分组展示
  Widget _buildPendingView(Map<String, List<Homework>> grouped, String studentId, int totalCount) {
    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 48, color: DesignTokens.textAux3),
            const SizedBox(height: DesignTokens.elementGapLarge),
            const Text('暂无家庭作业', style: TextStyle(
              fontSize: DesignTokens.cardTitleSize, color: DesignTokens.textSecondary,
            )),
            const SizedBox(height: DesignTokens.elementGap),
            const Text('点击右上角"+"添加作业', style: TextStyle(
              fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
            )),
          ],
        ),
      );
    }

    // 按截止日期排序分组
    final sortedKeys = grouped.keys.toList();
    sortedKeys.sort((a, b) {
      final dateA = HomeworkProvider.parseGroupKey(a).$2;
      final dateB = HomeworkProvider.parseGroupKey(b).$2;
      return dateA.compareTo(dateB);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupKey = sortedKeys[index];
        final tasks = grouped[groupKey]!;
        return _SubjectGroupCard(
          groupKey: groupKey,
          tasks: tasks,
          studentId: studentId,
          onAddTask: () => _addTaskToGroup(studentId, tasks.first.subject, tasks.first.dueDate),
        );
      },
    );
  }

  /// 已完成视图
  Widget _buildCompletedView(Map<String, List<Homework>> grouped, int totalCount) {
    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: DesignTokens.textAux3),
            const SizedBox(height: DesignTokens.elementGapLarge),
            const Text('暂无已完成作业', style: TextStyle(
              fontSize: DesignTokens.cardTitleSize, color: DesignTokens.textSecondary,
            )),
            const SizedBox(height: DesignTokens.elementGap),
            const Text('完成的作业会显示在这里', style: TextStyle(
              fontSize: DesignTokens.auxSize, color: DesignTokens.textAux1,
            )),
          ],
        ),
      );
    }

    final sortedKeys = grouped.keys.toList();
    sortedKeys.sort((a, b) {
      final dateA = HomeworkProvider.parseGroupKey(a).$2;
      final dateB = HomeworkProvider.parseGroupKey(b).$2;
      return dateB.compareTo(dateA); // 已完成按日期倒序
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupKey = sortedKeys[index];
        final tasks = grouped[groupKey]!;
        return _SubjectGroupCard(
          groupKey: groupKey,
          tasks: tasks,
          studentId: '',
          isCompletedView: true,
        );
      },
    );
  }

  void _addHomework(String studentId) async {
    final result = await showModalBottomSheet<Homework>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHomeworkDialog(studentId: studentId),
    );
    if (result != null) {
      context.read<HomeworkProvider>().addHomework(result);
    }
  }

  /// 向已有科目组添加新任务
  void _addTaskToGroup(String studentId, String subject, DateTime dueDate) async {
    final result = await showModalBottomSheet<Homework>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHomeworkDialog(
        studentId: studentId,
        prefillSubject: subject,
        prefillDueDate: dueDate,
      ),
    );
    if (result != null) {
      context.read<HomeworkProvider>().addHomework(result);
    }
  }
}

/// 科目分组卡片 —— 第一级UI
class _SubjectGroupCard extends StatelessWidget {
  final String groupKey;
  final List<Homework> tasks;
  final String studentId;
  final VoidCallback? onAddTask;
  final bool isCompletedView;

  const _SubjectGroupCard({
    required this.groupKey,
    required this.tasks,
    required this.studentId,
    this.onAddTask,
    this.isCompletedView = false,
  });

  @override
  Widget build(BuildContext context) {
    final (subject, dueDate) = HomeworkProvider.parseGroupKey(groupKey);
    final subjectColor = DesignTokens.subjectColors[subject];

    // 防御：空任务列表不渲染
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 计算该组的完成情况
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final isAllCompleted = completedCount == tasks.length && tasks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.cardGapLarge),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 科目头部（第一级）===
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.cardPadding, DesignTokens.cardPadding, DesignTokens.cardPadding, DesignTokens.elementGap),
            child: Row(
              children: [
                // 科目标签色块
                Container(
                  width: 6,
                  height: 28,
                  decoration: BoxDecoration(
                    color: subjectColor ?? DesignTokens.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: DesignTokens.elementGapLarge),
                // 科目名
                Expanded(child: Text(subject, style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textPrimary,
                ))),
                // 截止日期
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.pillBg,
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  child: Text('${dueDate.month}月${dueDate.day}日', style: const TextStyle(
                    fontSize: DesignTokens.tagSize, color: DesignTokens.textSecondary,
                  )),
                ),
                const SizedBox(width: DesignTokens.elementGap),
                // 进度指示
                if (!isCompletedView && tasks.isNotEmpty)
                  Text('$completedCount/${tasks.length}', style: TextStyle(
                    fontSize: DesignTokens.tagSize,
                    fontWeight: FontWeight.w600,
                    color: isAllCompleted ? DesignTokens.successText : DesignTokens.textAux1,
                  )),
                // 添加任务按钮（仅待完成模式）
                if (onAddTask != null && !isCompletedView) ...[
                  const SizedBox(width: DesignTokens.elementGap),
                  GestureDetector(
                    onTap: onAddTask,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: DesignTokens.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 16, color: DesignTokens.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // === 任务列表（第二级）===
          ...tasks.map((task) => _TaskRow(
            task: task,
            subjectColor: subjectColor,
            isLast: task == tasks.last,
          )),

          const SizedBox(height: DesignTokens.elementGap),
        ],
      ),
    );
  }
}

/// 单个任务行 —— 第二级UI
class _TaskRow extends StatefulWidget {
  final Homework task;
  final Color? subjectColor;
  final bool isLast;

  const _TaskRow({required this.task, required this.subjectColor, required this.isLast});

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeworkProvider>();
    final task = widget.task;
    final isCompleted = task.isCompleted;
    final subjectColor = widget.subjectColor ?? DesignTokens.accent;

    return GestureDetector(
      onTap: () => setState(() => _showActions = !_showActions),
      onLongPress: () => _editTask(context, task),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          DesignTokens.cardPadding + 14, // 缩进对齐科目标签
          DesignTokens.elementGap / 2,
          DesignTokens.cardPadding,
          widget.isLast ? DesignTokens.elementGap : 0,
        ),
        padding: const EdgeInsets.all(DesignTokens.elementGapLarge),
        decoration: BoxDecoration(
          color: isCompleted ? DesignTokens.successBg.withValues(alpha: 0.4) : DesignTokens.pillBg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 序号圆圈
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? DesignTokens.accent : Colors.white,
                border: Border.all(color: isCompleted ? DesignTokens.accent : DesignTokens.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('${task.taskOrder}', style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: DesignTokens.textSecondary,
                    )),
            ),
            const SizedBox(width: DesignTokens.elementGapLarge),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.content, style: TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: DesignTokens.bodyWeight,
                    color: isCompleted ? DesignTokens.textAux1 : DesignTokens.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  )),
                  if (task.category.isNotEmpty && task.category != '作业') ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(task.category, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600, color: subjectColor,
                      )),
                    ),
                  ],
                ],
              ),
            ),

            // 操作区
            if (_showActions && !isCompleted) ...[
              GestureDetector(
                onTap: () => _editTask(context, task),
                child: const Icon(Icons.edit_outlined, size: 18, color: DesignTokens.textAux1),
              ),
              const SizedBox(width: DesignTokens.elementGapLarge),
            ],

            // 完成勾选
            GestureDetector(
              onTap: () => provider.toggleComplete(task.id),
              behavior: HitTestBehavior.opaque,
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 26,
                color: isCompleted ? DesignTokens.accent : DesignTokens.textAux3,
              ),
            ),

            // 删除
            if (_showActions) ...[
              const SizedBox(width: DesignTokens.elementGap),
              GestureDetector(
                onTap: () => _confirmDelete(context, task),
                child: const Icon(Icons.delete_outline, size: 18, color: DesignTokens.pendingText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editTask(BuildContext context, Homework task) async {
    setState(() => _showActions = false);
    final result = await showModalBottomSheet<Homework>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHomeworkDialog(
        studentId: task.studentId,
        editingTask: task,
      ),
    );
    if (result != null) {
      context.read<HomeworkProvider>().updateHomework(result);
    }
  }

  void _confirmDelete(BuildContext context, Homework task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${task.content}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<HomeworkProvider>().deleteHomework(task.id);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.pendingText),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
