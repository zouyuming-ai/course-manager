import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';
import '../models/time_slot.dart';
import '../providers/time_slot_provider.dart';
import '../providers/semester_provider.dart';

/// 时间点编辑页
/// 支持新增和编辑时间点（节次、开始时间、结束时间、自定义标签）
class TimeSlotEditScreen extends StatefulWidget {
  final String? slotId; // 为空则是新增

  const TimeSlotEditScreen({super.key, this.slotId});

  @override
  State<TimeSlotEditScreen> createState() => _TimeSlotEditScreenState();
}

class _TimeSlotEditScreenState extends State<TimeSlotEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _period;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _labelController;

  bool get _isEditing => widget.slotId != null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();

    if (_isEditing) {
      // 编辑模式：从 provider 读取现有数据
      final timeSlot = context.read<TimeSlotProvider>().timeSlots.firstWhere(
        (ts) => ts.id == widget.slotId,
        orElse: () => TimeSlot(id: '', semesterId: '', period: 0, startTime: '08:00', endTime: '08:40'),
      );
      _period = timeSlot.period;
      _startTime = _parseTime(timeSlot.startTime);
      _endTime = _parseTime(timeSlot.endTime);
      _labelController.text = timeSlot.label;
    } else {
      // 新增模式：默认第1节，时间 8:30-9:10
      _period = 1;
      _startTime = const TimeOfDay(hour: 8, minute: 30);
      _endTime = const TimeOfDay(hour: 9, minute: 10);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final semesterProvider = context.read<SemesterProvider>();
    final timeSlotProvider = context.read<TimeSlotProvider>();
    final activeSemester = semesterProvider.activeSemester;

    if (activeSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择学期')),
      );
      return;
    }

    final timeSlot = TimeSlot(
      id: _isEditing ? widget.slotId! : '${activeSemester.id}_$_period',
      semesterId: activeSemester.id,
      period: _period,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      label: _labelController.text,
    );

    await timeSlotProvider.saveTimeSlot(timeSlot);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑时间点' : '新增时间点'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('保存', style: TextStyle(color: accentColor, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.pageMargin),
          children: [
            // 节次选择
            _buildSectionTitle('节次'),
            _buildPeriodSelector(),
            const SizedBox(height: DesignTokens.cardGap),

            // 开始时间
            _buildSectionTitle('开始时间'),
            _buildTimeButton(
              time: _startTime,
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: DesignTokens.cardGap),

            // 结束时间
            _buildSectionTitle('结束时间'),
            _buildTimeButton(
              time: _endTime,
              onTap: () => _pickTime(false),
            ),
            const SizedBox(height: DesignTokens.cardGap),

            // 自定义标签
            _buildSectionTitle('自定义标签（可选）'),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                hintText: '如：早读、第一节、大课间...',
                filled: true,
                fillColor: DesignTokens.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.elementGap),
            Text(
              '不填则使用默认标签',
              style: TextStyle(
                fontSize: DesignTokens.auxSize,
                color: DesignTokens.textAux2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.elementGap),
      child: Text(
        title,
        style: TextStyle(
          fontSize: DesignTokens.bodySize,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: DesignTokens.elementGap,
      children: List.generate(9, (index) {
        final label = index == 0 ? '早读' : '第$index节';
        final isSelected = _period == index;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _period = index),
          selectedColor: DesignTokens.accent,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : DesignTokens.textPrimary,
          ),
        );
      }),
    );
  }

  Widget _buildTimeButton({required TimeOfDay time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.cardGap),
        decoration: BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
