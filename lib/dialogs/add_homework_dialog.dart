import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/models/homework.dart';

/// 添加/编辑作业任务弹窗
/// 支持：新增任务、向已有科目组添加任务、编辑已有任务
/// ⚠️ 不使用系统 DatePicker（避免 locale/context 崩溃），改用内置日历网格
class AddHomeworkDialog extends StatefulWidget {
  final String studentId;

  /// 预填科目（向已有组添加时使用）
  final String? prefillSubject;
  /// 预填截止日期（向已有组添加时使用）
  final DateTime? prefillDueDate;
  /// 正在编辑的作业任务（非null=编辑模式）
  final Homework? editingTask;

  const AddHomeworkDialog({
    super.key,
    required this.studentId,
    this.prefillSubject,
    this.prefillDueDate,
    this.editingTask,
  });

  @override
  State<AddHomeworkDialog> createState() => _AddHomeworkDialogState();
}

class _AddHomeworkDialogState extends State<AddHomeworkDialog> {
  String _selectedSubject = '';
  final TextEditingController _contentController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _category = '作业';
  bool _showCalendar = false; // 内置日历展开状态

  static const List<String> _categories = ['作业', '背诵', '练习', '手工'];

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    // 预填模式或编辑模式的初始值设置
    if (_isEditing) {
      final t = widget.editingTask!;
      _selectedSubject = t.subject;
      _contentController.text = t.content;
      _dueDate = t.dueDate;
      _category = t.category;
    } else {
      if (widget.prefillSubject != null) {
        _selectedSubject = widget.prefillSubject!;
      }
      if (widget.prefillDueDate != null) {
        _dueDate = widget.prefillDueDate!;
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadiusLarge)),
        ),
        padding: const EdgeInsets.all(DesignTokens.cardPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(_isEditing ? '编辑作业' : '添加作业', style: const TextStyle(
                fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight, color: DesignTokens.textPrimary,
              )),
              const SizedBox(height: DesignTokens.elementGapLarge),

              // 科目选择
              if (!_isEditing || widget.prefillSubject == null)
                _buildSubjectSelector()
              else
                _buildReadOnlySubject(),
              const SizedBox(height: DesignTokens.cardGapLarge),

              // 作业内容
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '作业内容',
                  hintText: '如：完成练习册第10页',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.buttonRadius)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: DesignTokens.cardGapLarge),

              // 类别选择
              const Text('类别', style: TextStyle(
                fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
              )),
              const SizedBox(height: DesignTokens.elementGap),
              Row(
                children: _categories.map((cat) => GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    width: 70, height: 34,
                    margin: const EdgeInsets.only(right: DesignTokens.elementGap),
                    decoration: BoxDecoration(
                      color: _category == cat ? DesignTokens.accent : DesignTokens.pillBg,
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                    ),
                    alignment: Alignment.center,
                    child: Text(cat, style: TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: _category == cat ? FontWeight.w600 : DesignTokens.bodyWeight,
                      color: _category == cat ? Colors.white : DesignTokens.textSecondary,
                    )),
                  ),
                )).toList(),
              ),
              const SizedBox(height: DesignTokens.cardGapLarge),

              // 截止日期 — 内置日历选择器（不再依赖系统 DatePicker）
              _buildDateSelector(),
              if (_showCalendar) _buildCalendarGrid(),
              const SizedBox(height: DesignTokens.cardGapLarge * 2),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.accent,
                    foregroundColor: DesignTokens.textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                    ),
                  ),
                  child: Text(_isEditing ? '保存修改' : '保存'),
                ),
              ),

              // 底部安全间距（键盘弹出时需要）
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
            ],
          ),
        ),
      ),
    );
  }

  /// 只读科目标签（编辑模式或预填模式下显示）
  Widget _buildReadOnlySubject() {
    final subjectColor = DesignTokens.subjectColors[_selectedSubject];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('科目', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.cardPadding, vertical: 12),
          decoration: BoxDecoration(
            color: subjectColor ?? DesignTokens.pillBg,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Row(children: [
            Expanded(child: Text(_selectedSubject, style: TextStyle(
              fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight,
              color: (subjectColor?.computeLuminance() ?? 1) > 0.5 ? DesignTokens.textPrimary : Colors.white,
            ))),
            if (_isEditing) ...[
              const Text('（不可修改）', style: TextStyle(fontSize: DesignTokens.auxSize, color: DesignTokens.textAux2)),
              const SizedBox(width: 4),
            ],
          ]),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector() {
    final subjectColor = _selectedSubject.isNotEmpty
        ? DesignTokens.subjectColors[_selectedSubject]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('科目', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        GestureDetector(
          onTap: () => _showSubjectPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.cardPadding, vertical: 12),
            decoration: BoxDecoration(
              color: subjectColor ?? DesignTokens.pillBg,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              border: subjectColor == null ? Border.all(color: DesignTokens.border) : null,
            ),
            child: Row(children: [
              if (_selectedSubject.isNotEmpty)
                Expanded(child: Text(_selectedSubject, style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize, fontWeight: DesignTokens.cardTitleWeight,
                  color: subjectColor != null ? Colors.white : DesignTokens.textPrimary,
                )))
              else
                const Expanded(child: Text('点击选择科目', style: TextStyle(
                  fontSize: DesignTokens.bodySize, color: DesignTokens.textAux2,
                ))),
              const Icon(Icons.chevron_right, size: 20, color: DesignTokens.textAux1),
            ]),
          ),
        ),
      ],
    );
  }

  void _showSubjectPicker() {
    final subjects = DesignTokens.subjectColors.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadiusLarge)),
        ),
        padding: const EdgeInsets.all(DesignTokens.cardPadding),
        child: Wrap(
          spacing: DesignTokens.elementGap,
          runSpacing: DesignTokens.elementGap,
          children: subjects.map((s) => GestureDetector(
            onTap: () {
              setState(() => _selectedSubject = s);
              Navigator.of(ctx).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DesignTokens.subjectColors[s] ?? DesignTokens.pillBg,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
              ),
              child: Text(s, style: TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: FontWeight.w600,
                color: (DesignTokens.subjectColors[s]?.computeLuminance() ?? 1) > 0.5
                    ? DesignTokens.textPrimary : Colors.white,
              )),
            ),
          )).toList(),
        ),
      ),
    );
  }

  /// 截止日期选择 — 不使用系统 DatePicker，纯内置 UI
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('截止日期', style: TextStyle(
          fontSize: DesignTokens.bodySize, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary,
        )),
        const SizedBox(height: DesignTokens.elementGap),
        GestureDetector(
          onTap: () => setState(() => _showCalendar = !_showCalendar),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.cardPadding, vertical: 12),
            decoration: BoxDecoration(
              color: DesignTokens.pillBg,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              border: Border.all(color: DesignTokens.border),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 18, color: DesignTokens.accent),
              const SizedBox(width: DesignTokens.elementGap),
              Text('${_dueDate.month}月${_dueDate.day}日 ${_weekdayLabel(_dueDate.weekday)}', style: const TextStyle(
                fontSize: DesignTokens.bodySize, fontWeight: DesignTokens.bodyWeight, color: DesignTokens.textPrimary,
              )),
              const Spacer(),
              Icon(_showCalendar ? Icons.expand_less : Icons.expand_more, size: 20, color: DesignTokens.textAux1),
            ]),
          ),
        ),
      ],
    );
  }

  /// 内置日历网格 —— 选择未来14天内的日期
  Widget _buildCalendarGrid() {
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i + 1)));
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.elementGap),
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: DesignTokens.pillBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 星期标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) => SizedBox(
              width: 38,
              child: Center(child: Text(w, style: const TextStyle(
                fontSize: DesignTokens.tagSize, fontWeight: FontWeight.w600, color: DesignTokens.textAux1,
              ))),
            )).toList(),
          ),
          const SizedBox(height: DesignTokens.elementGap),

          // 日期网格
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: days.map((d) {
              final isSelected = d.year == _dueDate.year && d.month == _dueDate.month && d.day == _dueDate.day;
              final isWeekend = d.weekday == 6 || d.weekday == 7;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _dueDate = d;
                    _showCalendar = false;
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? DesignTokens.accent : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? null : Border.all(color: DesignTokens.border.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text('${d.day}', style: TextStyle(
                    fontSize: DesignTokens.bodySize,
                    fontWeight: isSelected ? FontWeight.w700 : DesignTokens.bodyWeight,
                    color: isSelected ? Colors.white : (isWeekend ? DesignTokens.pendingText : DesignTokens.textPrimary),
                  )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1: return '周一';
      case 2: return '周二';
      case 3: return '周三';
      case 4: return '周四';
      case 5: return '周五';
      case 6: return '周六';
      case 7: return '周日';
      default: return '';
    }
  }

  void _save() {
    if (_selectedSubject.isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择科目并填写作业内容')),
      );
      return;
    }

    final homework = Homework(
      id: _isEditing ? widget.editingTask!.id : 'hw_${DateTime.now().millisecondsSinceEpoch}',
      studentId: widget.studentId,
      subject: _selectedSubject,
      content: _contentController.text.trim(),
      dueDate: _dueDate,
      isCompleted: _isEditing ? widget.editingTask!.isCompleted : false,
      category: _category,
      taskOrder: _isEditing ? widget.editingTask!.taskOrder : 0, // 0表示自动分配
      completedDate: _isEditing ? widget.editingTask!.completedDate : null,
    );

    Navigator.of(context).pop(homework);
  }
}
