import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/screens/empty_state.dart';
import 'package:course_manager/widgets/student_card.dart';
import 'package:course_manager/dialogs/add_student_dialog.dart';

/// S2 学生管理页面
/// 设计规格：背景 #FFFAF0, 卡片列表, 添加按钮, 活跃学生指示条
class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final students = provider.students;

        return Scaffold(
          backgroundColor: DesignTokens.bg,
          appBar: AppBar(
            title: const Text('学生管理'),
            backgroundColor: DesignTokens.bg,
            elevation: 0,
            actions: [
              // 添加学生按钮
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                onPressed: () => _showAddDialog(context),
                tooltip: '添加学生',
              ),
            ],
          ),
          body: students.isEmpty
              ? StudentsEmptyState(
                  onAdd: () => _showAddDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.pageMargin,
                    vertical: DesignTokens.elementGap,
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isActive = provider.activeStudent?.id == student.id;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: DesignTokens.cardGap,
                      ),
                      child: StudentCard(
                        student: student,
                        isActive: isActive,
                        onSetActive: () {
                          provider.setActiveStudent(student.id);
                        },
                        onEdit: () => _showEditDialog(context, student),
                        onDelete: () => _confirmDelete(context, provider, student.id, student.name),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  /// 显示添加学生对话框
  void _showAddDialog(BuildContext context) {
    AddStudentDialog.show(context);
  }

  /// 显示编辑学生对话框
  void _showEditDialog(BuildContext context, dynamic student) {
    AddStudentDialog.show(context, student: student as Student);
  }

  /// 确认删除学生
  void _confirmDelete(BuildContext context, StudentProvider provider, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadiusLarge),
        ),
        title: Text(
          '确认删除',
          style: const TextStyle(
            fontSize: DesignTokens.titleSize,
            fontWeight: DesignTokens.titleWeight,
            color: DesignTokens.textPrimary,
          ),
        ),
        content: Text(
          '确定要删除"$name"吗？删除后该学生的所有课表数据也将被清除。',
          style: const TextStyle(
            fontSize: DesignTokens.bodySize,
            color: DesignTokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteStudent(id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accent,
              foregroundColor: DesignTokens.textPrimary,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
