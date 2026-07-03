import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/utils/subject_colors.dart';

/// 科目选择器 Bottom Sheet — S6 设计规格
/// 11个科目圆按钮（3~4列网格），选中状态外圈边框，底部自定义科目输入
/// 设计规格：Bottom Sheet 圆角顶部24px，标题"选择科目"18px/600

class SubjectSelector extends StatefulWidget {
  /// 当前选中的科目（用于回显选中状态）
  final String? currentSubject;

  const SubjectSelector({
    super.key,
    this.currentSubject,
  });

  /// 弹出科目选择器 Bottom Sheet，返回选中的科目名
  static Future<String?> showSubjectSelector(BuildContext context, {String? currentSubject}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadiusLarge),
        ),
      ),
      builder: (_) => SubjectSelector(currentSubject: currentSubject),
    );
  }

  @override
  State<SubjectSelector> createState() => _SubjectSelectorState();
}

class _SubjectSelectorState extends State<SubjectSelector> {
  String? _selectedSubject;
  final TextEditingController _customSubjectController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  bool _showCustomInput = false;

  /// 预置科目分类（按平面视觉颜色理论分类）
  /// 用作科目排序的参考顺序
  static const Map<String, int> _subjectCategoryOrder = {
    // 人文语言（暖色系）
    '语文': 10, '外语': 10, '英语': 10, '英拓': 10,
    '道德与法治': 10, '品德': 10, '道法': 10,
    // 逻辑科学（冷色系）
    '数学': 20, '科学': 20, '信息技术': 20,
    // 运动健康（自然绿色系）
    '体育': 30, '体育与健康': 30, '体活': 30,
    // 艺术创意（紫粉系）
    '音乐': 40, '唱游': 40, '美术': 40, '写字': 40,
    // 实践劳动（土色系）
    '劳动': 50, '劳动技术': 50,
    // 活动拓展（亮色系）
    '综合活动': 60, '快乐活动': 60, '兴活': 60,
    // 服务组织（中性色）
    '少先队活动': 70, '课后服务': 70, '班会': 70,
  };

  /// 获取动态科目列表（预置 + 自定义，去重，按分类排序）
  List<String> _getSortedSubjects(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final subjects = <String>{};

    // 从预设映射获取基础科目
    subjects.addAll(presetSubjectColorHex.keys);

    // 从自定义颜色中获取（用户可能为新科目设置了颜色）
    for (final sc in scheduleProvider.subjectColors) {
      subjects.add(sc.subject);
    }

    // 从已有课表中获取（发现新科目）
    for (final s in scheduleProvider.schedules) {
      if (s.subject.isNotEmpty) {
        subjects.add(s.subject);
      }
    }

    // 按分类排序
    final sorted = subjects.toList()
      ..sort((a, b) {
        final orderA = _subjectCategoryOrder[a] ?? 99;
        final orderB = _subjectCategoryOrder[b] ?? 99;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b); // 同类别内按名称排序
      });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.currentSubject;
  }

  @override
  void dispose() {
    _customSubjectController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  /// 判断科目颜色是否为浅色（需要深色文字）
  static bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// 选择科目
  void _onSubjectSelected(String subject) {
    setState(() {
      _selectedSubject = subject;
      _showCustomInput = false;
    });
    Navigator.pop(context, subject);
  }

  /// 提交自定义科目
  void _onCustomSubjectSubmitted() {
    final custom = _customSubjectController.text.trim();
    if (custom.isNotEmpty) {
      Navigator.pop(context, custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: DesignTokens.pageMargin,
        right: DesignTokens.pageMargin,
        top: DesignTokens.cardPadding,
        bottom: bottomInset + DesignTokens.cardPadding,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择科目',
                style: TextStyle(
                  fontSize: DesignTokens.titleSize,
                  fontWeight: DesignTokens.titleWeight,
                  color: DesignTokens.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  size: 24,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.cardGapLarge),

          // 科目按钮网格（可滚动，动态加载科目列表）
          Builder(
            builder: (context) {
              final subjects = _getSortedSubjects(context);
              return SizedBox(
                height: 320, // 固定高度，约5行
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: DesignTokens.elementGap,
                    crossAxisSpacing: DesignTokens.elementGap,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    // 正确获取科目颜色（自定义 > 预设 > DesignTokens > 回退）
                    final scheduleProvider = context.read<ScheduleProvider>();
                    final color = scheduleProvider.getSubjectColorValue(subject);
                    final isLight = _isLightColor(color);
                    final textColor = isLight ? DesignTokens.textPrimary : DesignTokens.card;
                    final isSelected = _selectedSubject == subject;

                    return GestureDetector(
                      onTap: () => _onSubjectSelected(subject),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(DesignTokens.circleRadius),
                          // 选中状态：外圈边框2px
                          border: isSelected
                              ? Border.all(color: DesignTokens.textPrimary, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          subject,
                          style: TextStyle(
                            fontSize: DesignTokens.bodySize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: DesignTokens.cardGap),

          // 自定义科目输入区域
          GestureDetector(
            onTap: () {
              setState(() {
                _showCustomInput = true;
              });
              _customFocusNode.requestFocus();
            },
            child: _showCustomInput
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customSubjectController,
                          focusNode: _customFocusNode,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '输入自定义科目名称',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _onCustomSubjectSubmitted(),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.elementGap),
                      ElevatedButton(
                        onPressed: _onCustomSubjectSubmitted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.accent,
                          foregroundColor: DesignTokens.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.cardPadding,
                            vertical: DesignTokens.elementGap,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                          ),
                        ),
                        child: const Text(
                          '确认',
                          style: TextStyle(
                            fontSize: DesignTokens.bodySize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.cardPadding,
                      vertical: DesignTokens.elementGap + 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: DesignTokens.border),
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 18,
                          color: DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: DesignTokens.elementGap),
                        Text(
                          '自定义科目',
                          style: const TextStyle(
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
}
