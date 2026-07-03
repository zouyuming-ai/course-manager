import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/models/semester.dart';

/// S9 学期管理页面（设置Tab内的子页面）
/// 支持添加、切换、删除学期

class SemesterScreen extends StatelessWidget {
  const SemesterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semesterProvider = context.watch<SemesterProvider>();
    final semesters = semesterProvider.semesters;
    final activeSemester = semesterProvider.activeSemester;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(title: const Text('学期管理')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.cardGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前学期卡片
            if (activeSemester != null)
              _ActiveSemesterCard(semester: activeSemester)
            else
              _NoSemesterCard(),

            const SizedBox(height: DesignTokens.cardGapLarge),

            // 所有学期列表
            if (semesters.isNotEmpty) ...[
              const Text(
                '所有学期',
                style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize,
                  fontWeight: DesignTokens.cardTitleWeight,
                  color: DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.elementGap),
              ...semesters.map((s) => _SemesterListItem(semester: s)),
              const SizedBox(height: DesignTokens.cardGapLarge),
            ],

            // 添加学期按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAddSemesterDialog(context),
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
                  '添加学期',
                  style: TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加学期对话框
  void _showAddSemesterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final schoolController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 140));
    int totalWeeks = 20;

    // 计算周数的辅助函数
    int calculateWeeks(DateTime start, DateTime end) {
      return ((end.difference(start).inDays) / 7).ceil();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加学期',
                    style: TextStyle(
                      fontSize: DesignTokens.cardTitleSize,
                      fontWeight: DesignTokens.cardTitleWeight,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.cardGap),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: '学期名称（如：2026春季学期）'),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  TextField(
                    controller: schoolController,
                    decoration: const InputDecoration(hintText: '学校名称（可选）'),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  // 起始日期选择
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          // 自动计算周数
                          totalWeeks = calculateWeeks(startDate, endDate);
                        });
                      }
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
                            '起始日期：${startDate.year}年${startDate.month}月${startDate.day}日',
                            style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
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
                        context: ctx,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                          // 自动计算周数
                          totalWeeks = calculateWeeks(startDate, endDate);
                        });
                      }
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
                            '结束日期：${endDate.year}年${endDate.month}月${endDate.day}日',
                            style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  // 总周数显示
                  Container(
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
                        const Icon(Icons.weekend_outlined, size: 20, color: DesignTokens.textSecondary),
                        const SizedBox(width: DesignTokens.elementGap),
                        Text(
                          '总周数：$totalWeeks 周',
                          style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.cardGapLarge),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入学期名称')),
                          );
                          return;
                        }
                        final semester = Semester(
                          id: 'semester_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameController.text.trim(),
                          schoolName: schoolController.text.trim(),
                          startDate: startDate,
                          endDate: endDate,
                          totalWeeks: totalWeeks,
                          isActive: true,
                        );
                        context.read<SemesterProvider>().addSemester(semester);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('学期添加成功')),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 编辑学期对话框
  static void showEditSemesterDialog(BuildContext context, Semester semester) {
    final nameController = TextEditingController(text: semester.name);
    final schoolController = TextEditingController(text: semester.schoolName);
    DateTime startDate = semester.startDate;
    DateTime endDate = semester.endDate;
    int totalWeeks = semester.totalWeeks;

    int calculateWeeks(DateTime start, DateTime end) {
      return ((end.difference(start).inDays) / 7).ceil();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '编辑学期',
                    style: TextStyle(
                      fontSize: DesignTokens.cardTitleSize,
                      fontWeight: DesignTokens.cardTitleWeight,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.cardGap),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: '学期名称（如：2026春季学期）'),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  TextField(
                    controller: schoolController,
                    decoration: const InputDecoration(hintText: '学校名称（可选）'),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          totalWeeks = calculateWeeks(startDate, endDate);
                        });
                      }
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
                            '起始日期：${startDate.year}年${startDate.month}月${startDate.day}日',
                            style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                          totalWeeks = calculateWeeks(startDate, endDate);
                        });
                      }
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
                            '结束日期：${endDate.year}年${endDate.month}月${endDate.day}日',
                            style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.elementGap),

                  Container(
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
                        const Icon(Icons.weekend_outlined, size: 20, color: DesignTokens.textSecondary),
                        const SizedBox(width: DesignTokens.elementGap),
                        Text(
                          '总周数：$totalWeeks 周',
                          style: const TextStyle(fontSize: DesignTokens.bodySize, color: DesignTokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.cardGapLarge),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入学期名称')),
                          );
                          return;
                        }
                        // ✅ 直接修改原有对象的属性（不创建新对象）
                        semester.name = nameController.text.trim();
                        semester.schoolName = schoolController.text.trim();
                        semester.startDate = startDate;
                        semester.endDate = endDate;
                        semester.totalWeeks = totalWeeks;
                        context.read<SemesterProvider>().updateSemester(semester);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('学期已更新')),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 活跃学期卡片
class _ActiveSemesterCard extends StatelessWidget {
  final Semester semester;

  const _ActiveSemesterCard({required this.semester});

  @override
  Widget build(BuildContext context) {
    // 计算当前周数
    final now = DateTime.now();
    final daysDiff = now.difference(semester.startDate).inDays;
    final currentWeek = (daysDiff / 7).floor() + 1;
    final displayWeek = currentWeek.clamp(1, semester.totalWeeks);

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学期名称
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '当前学期',
                  style: TextStyle(
                    fontSize: DesignTokens.tagSize,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.accent,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          Text(
            semester.name,
            style: const TextStyle(
              fontSize: DesignTokens.cardTitleSizeLarge,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 学校名称
          if (semester.schoolName.isNotEmpty)
            _InfoRow(icon: Icons.school_outlined, text: semester.schoolName),

          // 起止日期
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: '${_formatDate(semester.startDate)} - ${_formatDate(semester.endDate)}',
          ),

          // 总周数
          _InfoRow(icon: Icons.weekend_outlined, text: '共 ${semester.totalWeeks} 周'),

          // 当前周数指示
          const SizedBox(height: DesignTokens.elementGapLarge),
          Row(
            children: [
              Text(
                '第 $displayWeek 周',
                style: const TextStyle(
                  fontSize: DesignTokens.auxSize,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.elementGap),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: displayWeek / semester.totalWeeks,
                    backgroundColor: DesignTokens.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DesignTokens.accent,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.elementGap),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DesignTokens.textAux1),
          const SizedBox(width: DesignTokens.elementGap),
          Text(
            text,
            style: const TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 无学期卡片
class _NoSemesterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      child: const Column(
        children: [
          Icon(Icons.school_outlined, size: 40, color: DesignTokens.textAux3),
          SizedBox(height: DesignTokens.elementGap),
          Text(
            '还没有设置学期',
            style: TextStyle(
              fontSize: DesignTokens.cardTitleSize,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          SizedBox(height: DesignTokens.elementGap),
          Text(
            '添加一个学期，开始管理课表和书包',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              fontWeight: DesignTokens.bodyWeight,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 学期列表项
class _SemesterListItem extends StatelessWidget {
  final Semester semester;

  const _SemesterListItem({required this.semester});

  @override
  Widget build(BuildContext context) {
    final isActive = semester.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.elementGap),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: isActive
            ? Border.all(color: DesignTokens.accent, width: 2)
            : Border.all(color: DesignTokens.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.cardPadding,
          vertical: DesignTokens.elementGap,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? DesignTokens.accent.withValues(alpha: 0.15)
                : DesignTokens.bg,
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          child: Icon(
            Icons.calendar_today_outlined,
            color: isActive ? DesignTokens.accent : DesignTokens.textAux1,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              semester.name,
              style: TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: FontWeight.w600,
                color: isActive ? DesignTokens.accent : DesignTokens.textPrimary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '当前',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${semester.startDate.year}年${semester.startDate.month}月 - ${semester.endDate.year}年${semester.endDate.month}月',
              style: const TextStyle(
                fontSize: DesignTokens.auxSize,
                color: DesignTokens.textSecondary,
              ),
            ),
            if (semester.schoolName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                semester.schoolName,
                style: const TextStyle(
                  fontSize: DesignTokens.auxSize,
                  color: DesignTokens.textAux1,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: DesignTokens.accent),
              onPressed: () => SemesterScreen.showEditSemesterDialog(context, semester),
            ),
            // 切换按钮
            if (!isActive)
              TextButton(
                onPressed: () {
                  context.read<SemesterProvider>().setActiveSemester(semester.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已切换到：${semester.name}')),
                  );
                },
                child: const Text('切换'),
              ),
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除学期「${semester.name}」吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<SemesterProvider>().deleteSemester(semester.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('学期已删除')),
                          );
                        },
                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
