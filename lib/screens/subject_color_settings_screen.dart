import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import '../utils/subject_colors.dart';
import '../providers/schedule_provider.dart';
import '../models/subject_color.dart';

/// 科目颜色设置页面
/// 支持自定义每个科目的显示颜色
class SubjectColorSettingsScreen extends StatefulWidget {
  const SubjectColorSettingsScreen({super.key});

  @override
  State<SubjectColorSettingsScreen> createState() => _SubjectColorSettingsScreenState();
}

class _SubjectColorSettingsScreenState extends State<SubjectColorSettingsScreen> {
  /// 预设调色盘（精选30色，覆盖常用色系）
  static const List<Color> _colorPalette = [
    // ── 红色系 ──
    Color(0xFFEF5350), Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828),
    // ── 橙色系 ──
    Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFF57C00), Color(0xFFE65100),
    Color(0xFFFF8C7A), Color(0xFFFF6B6B),
    // ── 黄色系 ──
    Color(0xFFFFEE58), Color(0xFFFFD54F), Color(0xFFFFC857), Color(0xFFFFB300),
    // ── 绿色系 ──
    Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF43A047), Color(0xFF388E3C),
    Color(0xFF7BB661),
    // ── 青色系 ──
    Color(0xFF26C6DA), Color(0xFF00BCD4), Color(0xFF00ACC1),
    // ── 蓝色系 ──
    Color(0xFF6BB6E0), Color(0xFF42A5F5), Color(0xFF2196F3), Color(0xFF1E88E5),
    Color(0xFF3498DB), Color(0xFF5C6BC0),
    // ── 紫色系 ──
    Color(0xFFAB47BC), Color(0xFF9B59B6), Color(0xFF8E44AD), Color(0xFFEC407A),
    Color(0xFFFF6B9D), Color(0xFFE91E63),
    // ── 中性系 ──
    Color(0xFF78909C), Color(0xFF90A4AE), Color(0xFF607D8B),
  ];

  late Map<String, String> _customColors;

  @override
  void initState() {
    super.initState();
    _loadCustomColors();
  }

  void _loadCustomColors() {
    final scheduleProvider = context.read<ScheduleProvider>();
    _customColors = {};
    for (final sc in scheduleProvider.subjectColors) {
      _customColors[sc.subject] = sc.color;
    }
  }

  /// 获取科目的实际颜色（自定义 > 预设）
  Color _getColorForSubject(String subject) {
    final customHex = _customColors[subject];
    if (customHex != null && customHex.isNotEmpty) {
      return hexToColor(customHex);
    }
    return getColorForSubject(subject, null);
  }

  /// 获取所有已知的科目列表（去重排序）
  List<String> _getAllSubjects() {
    final scheduleProvider = context.read<ScheduleProvider>();
    final subjects = <String>{};

    // 从预设映射获取
    subjects.addAll(presetSubjectColorHex.keys);

    // 从已有课表中获取（发现新科目）
    for (final s in scheduleProvider.schedules) {
      if (s.subject.isNotEmpty) {
        subjects.add(s.subject);
      }
    }

    // 排序：按分类分组
    final sorted = subjects.toList()
      ..sort((a, b) => _categoryOrder(a).compareTo(_categoryOrder(b)));
    return sorted;
  }

  int _categoryOrder(String subject) {
    // 核心学科-暖色
    if (['语文', '外语', '英语', '英拓', '道德与法治', '品德', '道法'].contains(subject)) return 10;
    // 核心学科-冷色
    if (['数学', '科学', '信息技术'].contains(subject)) return 20;
    // 运动
    if (['体育', '体育与健康', '体活'].contains(subject)) return 30;
    // 艺术
    if (['音乐', '唱游', '美术', '写字'].contains(subject)) return 40;
    // 劳动
    if (['劳动', '劳动技术'].contains(subject)) return 50;
    // 活动
    if (['综合活动', '快乐活动', '兴活', '班会'].contains(subject)) return 60;
    // 服务/组织
    if (['课后服务', '少先队活动'].contains(subject)) return 70;
    return 99; // 其他
  }

  String _categoryLabel(String subject) {
    if (['语文', '外语', '英语', '英拓', '道德与法治', '品德', '道法'].contains(subject)) return '人文语言';
    if (['数学', '科学', '信息技术'].contains(subject)) return '逻辑科学';
    if (['体育', '体育与健康', '体活'].contains(subject)) return '运动健康';
    if (['音乐', '唱游', '美术', '写字'].contains(subject)) return '艺术创意';
    if (['劳动', '劳动技术'].contains(subject)) return '实践劳动';
    if (['综合活动', '快乐活动', '兴活', '班会'].contains(subject)) return '活动拓展';
    if (['课后服务', '少先队活动'].contains(subject)) return '服务组织';
    return '其他';
  }

  Future<void> _pickColor(BuildContext context, String subject) async {
    final currentColor = _getColorForSubject(subject);

    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        title: subject,
        currentColor: currentColor,
        palette: _colorPalette,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _customColors[subject] = '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      });

      final scheduleProvider = context.read<ScheduleProvider>();
      // 使用 studentId='global' 表示全局颜色设置
      scheduleProvider.setSubjectColor(SubjectColor(
        id: 'color_$subject',
        studentId: 'global',
        subject: subject,
        color: _customColors[subject]!,
      ));
    }
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认颜色'),
        content: const Text('将所有科目颜色恢复为系统预设值？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final scheduleProvider = context.read<ScheduleProvider>();
              // 删除所有自定义颜色
              for (final sc in List.of(scheduleProvider.subjectColors)) {
                scheduleProvider.deleteSubjectColor(sc.id);
              }
              setState(() {
                _customColors.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 已恢复默认颜色'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }

  /// 添加新科目
  void _addNewSubject() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加新科目'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入科目名称',
            isDense: true,
          ),
          onSubmitted: (_) {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(ctx).pop(name);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop(name);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name is String && name.isNotEmpty && mounted) {
        // 为新科目设置默认颜色
        setState(() {
          _customColors[name] = '#FFC857'; // 默认琥珀黄
        });

        final scheduleProvider = context.read<ScheduleProvider>();
        scheduleProvider.setSubjectColor(SubjectColor(
          id: 'color_$name',
          studentId: 'global',
          subject: name,
          color: '#FFC857',
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已添加科目 "$name"'), duration: const Duration(seconds: 2)),
        );
      }
    });
  }

  /// 删除科目（同时删除该科目的所有课程和颜色）
  void _deleteSubject(String subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除科目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除科目 "$subject" 吗？'),
            const SizedBox(height: 8),
            // 统计该科目的课程数量
            Builder(
              builder: (ctx2) {
                final scheduleProvider = ctx2.read<ScheduleProvider>();
                final courseCount = scheduleProvider.schedules
                    .where((s) => s.subject == subject)
                    .length;
                if (courseCount > 0) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFB74D)),
                    ),
                    child: Text(
                      '⚠️ 同时删除 $courseCount 条相关课程',
                      style: TextStyle(
                        fontSize: DesignTokens.tagSize,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final scheduleProvider = context.read<ScheduleProvider>();

              // 1. 删除该科目的所有课程
              final coursesToDelete = scheduleProvider.schedules
                  .where((s) => s.subject == subject)
                  .toList();
              for (final c in coursesToDelete) {
                scheduleProvider.deleteSchedule(c.id);
              }

              // 2. 删除该科目的自定义颜色
              final colorsToDelete = scheduleProvider.subjectColors
                  .where((c) => c.subject == subject)
                  .toList();
              for (final sc in colorsToDelete) {
                scheduleProvider.deleteSubjectColor(sc.id);
              }

              setState(() {
                _customColors.remove(subject);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ 已删除科目 "$subject" 及 ${coursesToDelete.length} 门课程'), duration: const Duration(seconds: 3)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  /// 编辑科目名称
  void _renameSubject(String oldName) {
    final controller = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改科目名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的科目名称',
            isDense: true,
          ),
          onSubmitted: (_) {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && newName != oldName) {
              Navigator.of(ctx).pop(newName);
            } else {
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                Navigator.of(ctx).pop(newName);
              } else {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ).then((result) {
      if (result is String && result.isNotEmpty && result != oldName && mounted) {
        final scheduleProvider = context.read<ScheduleProvider>();
        final colorHex = _customColors[oldName];

        // 1. 更新所有使用该科目的课程
        final coursesToUpdate = scheduleProvider.schedules
            .where((s) => s.subject == oldName)
            .toList();
        for (final c in coursesToUpdate) {
          scheduleProvider.updateScheduleSubject(c.id, result);
        }

        // 2. 更新颜色映射（删除旧的，创建新的）
        if (colorHex != null) {
          final colorsToDelete = scheduleProvider.subjectColors
              .where((c) => c.subject == oldName)
              .toList();
          for (final sc in colorsToDelete) {
            scheduleProvider.deleteSubjectColor(sc.id);
          }
          scheduleProvider.setSubjectColor(SubjectColor(
            id: 'color_$result',
            studentId: 'global',
            subject: result,
            color: colorHex,
          ));
        }

        setState(() {
          _customColors.remove(oldName);
          if (colorHex != null) {
            _customColors[result] = colorHex;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已将 "$oldName" 修改为 "$result"'), duration: const Duration(seconds: 2)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSubjects = _getAllSubjects();

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('科目颜色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: '添加科目',
            onPressed: _addNewSubject,
          ),
          IconButton(
            icon: const Icon(Icons.restore_outlined, size: 22),
            tooltip: '恢复默认',
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.elementGap,
        ),
        itemCount: allSubjects.length,
        itemBuilder: (context, index) {
          final subject = allSubjects[index];
          final color = _getColorForSubject(subject);
          final isCustom = _customColors.containsKey(subject);
          final category = _categoryLabel(subject);

          // 分组标题（类别变化时显示）
          final showHeader = index == 0 || _categoryLabel(allSubjects[index - 1]) != category;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                SizedBox(height: index > 0 ? DesignTokens.cardGap : 0),
                Padding(
                  padding: const EdgeInsets.only(left: DesignTokens.elementGap, bottom: DesignTokens.elementGap),
                  child: Text(category, style: TextStyle(
                    fontSize: DesignTokens.auxSize,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textAux1,
                  )),
                ),
              ],
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.elementGap,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.buttonRadius)),
                leading: GestureDetector(
                  onTap: () => _pickColor(context, subject),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(DesignTokens.circleRadius),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isCustom
                        ? const Icon(Icons.edit, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                title: Text(subject, style: const TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w500,
                )),
                subtitle: isCustom
                    ? Text('自定义', style: TextStyle(
                        fontSize: DesignTokens.tagSize,
                        color: DesignTokens.textAux1,
                      ))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustom) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                        tooltip: '修改名称',
                        onPressed: () => _renameSubject(subject),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: '删除科目',
                        onPressed: () => _deleteSubject(subject),
                      ),
                    ],
                    const Icon(Icons.chevron_right, size: 18, color: DesignTokens.textAux2),
                  ],
                ),
                onTap: () => _pickColor(context, subject),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 颜色选择对话框
class _ColorPickerDialog extends StatelessWidget {
  final String title;
  final Color currentColor;
  final List<Color> palette;

  const _ColorPickerDialog({
    required this.title,
    required this.currentColor,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('"$title" 的颜色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前颜色预览
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // 预设调色盘
            Text('选择颜色', style: TextStyle(
              fontSize: DesignTokens.auxSize,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textAux1,
            )),
            const SizedBox(height: DesignTokens.elementGap),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: palette.map((color) {
                final isSelected = color.toARGB32() == currentColor.toARGB32();
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: DesignTokens.textPrimary, width: 3)
                          : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
