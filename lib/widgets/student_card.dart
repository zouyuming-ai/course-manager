import 'package:flutter/material.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/models/student.dart';
import 'package:course_manager/utils/subject_colors.dart';

/// 学生卡片组件
/// 设计规格：圆角16px白色背景, 左侧头像, 中间姓名+年级班级, 右侧活跃指示/三点菜单
/// 活跃学生：左侧4px琥珀色指示条
class StudentCard extends StatelessWidget {
  final Student student;
  final bool isActive;
  final VoidCallback? onSetActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StudentCard({
    super.key,
    required this.student,
    required this.isActive,
    this.onSetActive,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 解析头像颜色
    final avatarColor = hexToColor(student.avatarColor);
    // 取姓名首字作为头像文字
    final initial = student.name.isNotEmpty ? student.name[0] : '?';

    return GestureDetector(
      onTap: onSetActive,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            // 活跃学生左侧指示条
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: isActive ? DesignTokens.accent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.cardRadius),
                  bottomLeft: Radius.circular(DesignTokens.cardRadius),
                ),
              ),
            ),

            // 卡片主体内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.cardPadding),
                child: Row(
                  children: [
                    // 圆形头像
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: DesignTokens.cardTitleSize,
                          fontWeight: DesignTokens.cardTitleWeight,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: DesignTokens.elementGapLarge),

                    // 姓名 + 年级班级
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: DesignTokens.cardTitleSize,
                              fontWeight: DesignTokens.cardTitleWeight,
                              color: DesignTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.grade}${student.className}',
                            style: const TextStyle(
                              fontSize: DesignTokens.bodySize,
                              fontWeight: DesignTokens.bodyWeight,
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 当前学生指示
                    if (isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DesignTokens.accent,
                          shape: BoxShape.circle,
                        ),
                      ),

                    const SizedBox(width: DesignTokens.elementGap),

                    // 三点菜单
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: DesignTokens.textAux1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('编辑'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
