import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/reminder_provider.dart';
import 'package:course_manager/models/reminder.dart';

/// S7a 添加/编辑提醒 Bottom Sheet
/// 包含：内容输入、类别选择、日期/时间选择、提前提醒、重复规则
/// 支持 editingReminder 参数进入编辑模式

class AddReminderDialog extends StatefulWidget {
  final String studentId;

  /// 正在编辑的提醒（非null=编辑模式）
  final Reminder? editingReminder;

  const AddReminderDialog({super.key, required this.studentId, this.editingReminder});

  /// 是否处于编辑模式
  bool get isEditing => editingReminder != null;

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _contentController = TextEditingController();
  String _category = '物品'; // 默认类别
  DateTime _reminderDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  int _notifyBeforeMinutes = 30;
  String _repeatRule = 'none';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final r = widget.editingReminder!;
      _contentController.text = r.content;
      _category = r.category;
      _reminderDate = r.reminderDate;
      // 解析时间字符串 "HH:mm"
      final timeParts = r.reminderTime.split(':');
      if (timeParts.length == 2) {
        _reminderTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
      _notifyBeforeMinutes = _normalizeNotifyBeforeMinutes(r.notifyBeforeMinutes);
      _repeatRule = r.repeatRule;
    }
  }

  /// 将旧的提醒提前分钟数迁移到新的选项集合中
  static int _normalizeNotifyBeforeMinutes(int value) {
    // 新的有效选项
    final validValues = _notifyOptions.map((o) => o.value as int).toSet();
    if (validValues.contains(value)) return value;

    // 旧数据 "当天早上" 是 360 分钟（6小时），映射到最接近的1小时
    if (value == 360) return 60;

    // 其他异常值，默认回到30分钟
    return 30;
  }

  /// 类别选项
  static final List<_CategoryOption> _categories = [
    _CategoryOption(label: '表单', icon: Icons.description_outlined, color: DesignTokens.pendingText),
    _CategoryOption(label: '物品', icon: Icons.inventory_2_outlined, color: DesignTokens.accent),
    _CategoryOption(label: '活动', icon: Icons.emoji_events_outlined, color: DesignTokens.subjectColors['唱游'] ?? DesignTokens.textAux1),
  ];

  /// 提前提醒选项
  static const List<_SelectOption> _notifyOptions = [
    _SelectOption(label: '准时提醒', value: 0),
    _SelectOption(label: '提前5分钟', value: 5),
    _SelectOption(label: '提前10分钟', value: 10),
    _SelectOption(label: '提前15分钟', value: 15),
    _SelectOption(label: '提前20分钟', value: 20),
    _SelectOption(label: '提前25分钟', value: 25),
    _SelectOption(label: '提前30分钟', value: 30),
    _SelectOption(label: '提前45分钟', value: 45),
    _SelectOption(label: '提前1小时', value: 60),
  ];

  /// 重复规则选项
  static const List<_SelectOption> _repeatOptions = [
    _SelectOption(label: '不重复', value: 'none'),
    _SelectOption(label: '每周', value: 'weekly'),
    _SelectOption(label: '每天', value: 'daily'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.cardRadiusLarge),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                widget.isEditing ? '编辑提醒' : '添加提醒',
                style: TextStyle(
                  fontSize: DesignTokens.cardTitleSize,
                  fontWeight: DesignTokens.cardTitleWeight,
                  color: DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.cardGapLarge),

              // 提醒内容输入
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '提醒内容',
                  prefixIcon: Icon(Icons.edit_outlined, size: 20),
                ),
              ),
              const SizedBox(height: DesignTokens.cardGap),

              // 类别选择
              const Text(
                '类别',
                style: TextStyle(
                  fontSize: DesignTokens.auxSize,
                  fontWeight: DesignTokens.auxWeight,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.elementGap),
              Row(
                children: _categories.map((cat) {
                  final isSelected = _category == cat.label;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat.label),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.15)
                              : DesignTokens.pillBg,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.buttonRadiusLarge,
                          ),
                          border: isSelected
                              ? Border.all(color: cat.color, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              size: 18,
                              color: isSelected ? cat.color : DesignTokens.textAux1,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: DesignTokens.auxSize,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? cat.color : DesignTokens.textAux1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.cardGap),

              // 提醒日期
              _buildDatePicker(context),
              const SizedBox(height: DesignTokens.cardGap),

              // 提醒时间
              _buildTimePicker(context),
              const SizedBox(height: DesignTokens.cardGap),

              // 提前提醒
              _buildDropdown(
                label: '提前提醒',
                options: _notifyOptions,
                currentValue: _notifyBeforeMinutes,
                onChanged: (v) => setState(() => _notifyBeforeMinutes = v),
              ),
              const SizedBox(height: DesignTokens.cardGap),

              // 重复规则
              _buildDropdown(
                label: '重复规则',
                options: _repeatOptions,
                currentValue: _repeatRule,
                onChanged: (v) => setState(() => _repeatRule = v),
              ),
              const SizedBox(height: DesignTokens.cardGapLarge),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveReminder,
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
                  child: Text(
                    widget.isEditing ? '保存修改' : '保存',
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
      ),
    );
  }

  /// 日期选择器行
  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _reminderDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: DesignTokens.accent,
                onPrimary: DesignTokens.textPrimary,
                surface: DesignTokens.card,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _reminderDate = picked);
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
              _formatDate(_reminderDate),
              style: const TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: DesignTokens.bodyWeight,
                color: DesignTokens.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: DesignTokens.textAux3),
          ],
        ),
      ),
    );
  }

  /// 时间选择器行
  Widget _buildTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _reminderTime,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: DesignTokens.accent,
                onPrimary: DesignTokens.textPrimary,
                surface: DesignTokens.card,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _reminderTime = picked);
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
            const Icon(Icons.access_time_outlined, size: 20, color: DesignTokens.textSecondary),
            const SizedBox(width: DesignTokens.elementGap),
            Text(
              _formatTime(_reminderTime),
              style: const TextStyle(
                fontSize: DesignTokens.bodySize,
                fontWeight: DesignTokens.bodyWeight,
                color: DesignTokens.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: DesignTokens.textAux3),
          ],
        ),
      ),
    );
  }

  /// 下拉选择行
  Widget _buildDropdown<T>({
    required String label,
    required List<_SelectOption> options,
    required T currentValue,
    required ValueChanged<T> onChanged,
  }) {
    final currentLabel = options.firstWhere(
      (o) => o.value == currentValue,
      orElse: () => options.isNotEmpty ? options.first : const _SelectOption(label: '', value: null),
    ).label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.auxSize,
            fontWeight: DesignTokens.auxWeight,
            color: DesignTokens.textSecondary,
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
          child: PopupMenuButton<T>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            color: DesignTokens.card,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentLabel,
                    style: const TextStyle(
                      fontSize: DesignTokens.bodySize,
                      fontWeight: DesignTokens.bodyWeight,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20, color: DesignTokens.textAux3),
              ],
            ),
            itemBuilder: (ctx) => options.map((opt) => PopupMenuItem<T>(
              value: opt.value as T,
              child: Text(opt.label),
            )).toList(),
            onSelected: onChanged,
          ),
        ),
      ],
    );
  }

  /// 保存提醒（新增或编辑）
  void _saveReminder() {
    if (_contentController.text.trim().isEmpty) return;

    final reminder = Reminder(
      id: widget.isEditing ? widget.editingReminder!.id : 'reminder_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}',
      studentId: widget.studentId,
      content: _contentController.text.trim(),
      category: _category,
      reminderDate: _reminderDate,
      reminderTime: _formatTime(_reminderTime),
      isCompleted: widget.isEditing ? widget.editingReminder!.isCompleted : false,
      repeatRule: _repeatRule,
      notifyBeforeMinutes: _notifyBeforeMinutes,
    );

    if (widget.isEditing) {
      context.read<ReminderProvider>().updateReminder(reminder);
    } else {
      context.read<ReminderProvider>().addReminder(reminder);
    }
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';
  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// 类别选项
class _CategoryOption {
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryOption({required this.label, required this.icon, required this.color});
}

/// 通用下拉选项
class _SelectOption {
  final String label;
  final dynamic value;
  const _SelectOption({required this.label, required this.value});
}
