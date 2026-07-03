import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/utils/subject_colors.dart';

/// 添加/编辑学生对话框
/// 设计规格：Bottom Sheet弹出, 学生姓名/年级/班级/头像颜色选择
class AddStudentDialog extends StatefulWidget {
  /// 编辑模式传入的学生（null为新建模式）
  final Student? student;

  const AddStudentDialog({super.key, this.student});

  /// 显示对话框
  static Future<void> show(BuildContext context, {Student? student}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadiusLarge),
        ),
      ),
      builder: (ctx) => AddStudentDialog(student: student),
    );
  }

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  late TextEditingController _nameController;
  late TextEditingController _classController;
  String _selectedGrade = '一年级';
  String _selectedColor = '#FFC857';

  /// 预设头像颜色
  static const List<String> _presetColors = [
    '#FFC857', // 活力琥珀黄
    '#FF8C7A', // 语文红
    '#6BB6E0', // 数学蓝
    '#7BB661', // 体育绿
    '#FF6B9D', // 音乐粉
    '#9B59B6', // 美术紫
    '#E67E22', // 品德橙
    '#3498DB', // 科学蓝
  ];

  /// 年级列表
  static const List<String> _grades = [
    '一年级', '二年级', '三年级',
    '四年级', '五年级', '六年级',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameController = TextEditingController(text: s?.name ?? '');
    _classController = TextEditingController(text: s?.className ?? '');
    _selectedGrade = s?.grade ?? '一年级';
    _selectedColor = s?.avatarColor ?? '#FFC857';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.pageMargin,
        right: DesignTokens.pageMargin,
        top: DesignTokens.cardGapLarge,
        bottom: bottomPadding + DesignTokens.pageMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            isEditing ? '编辑学生' : '添加学生',
            style: const TextStyle(
              fontSize: DesignTokens.titleSize,
              fontWeight: DesignTokens.titleWeight,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 学生姓名
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '学生姓名',
              hintText: '请输入姓名',
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          // 年级选择
          _buildGradeSelector(),
          const SizedBox(height: DesignTokens.elementGapLarge),

          // 班级输入
          TextField(
            controller: _classController,
            decoration: const InputDecoration(
              labelText: '班级',
              hintText: '如：2班',
            ),
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),

          // 头像颜色选择
          _buildColorSelector(),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 保存 + 取消按钮
          Row(
            children: [
              // 取消按钮
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: DesignTokens.elementGapLarge),
              // 保存按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.accent,
                    foregroundColor: DesignTokens.textPrimary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 年级下拉选择器
  Widget _buildGradeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '年级',
          style: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.elementGap),
        DropdownButtonFormField<String>(
          value: _selectedGrade,
          decoration: const InputDecoration(
            hintText: '选择年级',
          ),
          items: _grades.map((g) => DropdownMenuItem(
            value: g,
            child: Text(g),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGrade = val);
          },
        ),
      ],
    );
  }

  /// 头像颜色选择器
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '头像颜色',
          style: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.elementGap),
        Row(
          children: _presetColors.map((hex) {
            final color = hexToColor(hex);
            final isSelected = hex == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = hex),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: DesignTokens.elementGap),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: DesignTokens.textPrimary, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 保存学生信息
  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入学生姓名')),
      );
      return;
    }

    final provider = context.read<StudentProvider>();

    if (widget.student != null) {
      // 编辑模式
      final s = widget.student!;
      s.name = name;
      s.grade = _selectedGrade;
      s.className = _classController.text.trim();
      s.avatarColor = _selectedColor;
      provider.updateStudent(s);
    } else {
      // 新建模式
      final id = 'student_${DateTime.now().millisecondsSinceEpoch}';
      final student = Student(
        id: id,
        name: name,
        grade: _selectedGrade,
        className: _classController.text.trim(),
        avatarColor: _selectedColor,
      );
      provider.addStudent(student);
    }

    Navigator.of(context).pop();
  }
}
