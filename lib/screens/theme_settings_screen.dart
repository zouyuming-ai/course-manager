import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';

/// S17 自定义主题外观
/// 10色调板 + 字体大小 + 显示设置开关 + 深色模式 + 科目颜色
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.bgColor,
      appBar: AppBar(title: const Text('主题外观')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.pageMargin, vertical: DesignTokens.cardGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 深色模式 ===
            _buildSectionTitle('外观模式', themeProvider),
            const SizedBox(height: DesignTokens.elementGap),
            _buildDarkModeToggle(themeProvider),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // === 主题色板 ===
            _buildSectionTitle('主题色板', themeProvider),
            const SizedBox(height: DesignTokens.elementGapLarge),
            _buildColorPalette(themeProvider),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // === 字体大小 ===
            _buildSectionTitle('字体大小', themeProvider),
            const SizedBox(height: DesignTokens.elementGapLarge),
            _buildFontSizeSelector(themeProvider),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // === 显示设置 ===
            _buildSectionTitle('显示设置', themeProvider),
            const SizedBox(height: DesignTokens.elementGap),
            _buildToggleItem(
              icon: Icons.calendar_view_week,
              title: '显示周末列',
              subtitle: '在课表中显示周六周日',
              value: themeProvider.showWeekend,
              onChanged: (_) => themeProvider.toggleShowWeekend(),
              themeProvider: themeProvider,
            ),
            const SizedBox(height: DesignTokens.elementGap),
            _buildToggleItem(
              icon: Icons.schedule,
              title: '显示上课时间',
              subtitle: '在课表中显示每节课的时间段',
              value: themeProvider.showClassTime,
              onChanged: (_) => themeProvider.toggleShowClassTime(),
              themeProvider: themeProvider,
            ),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // === 科目颜色 ===
            _buildSectionTitle('科目颜色', themeProvider),
            const SizedBox(height: DesignTokens.elementGap),
            _buildSubjectColorEntry(themeProvider, context),
            const SizedBox(height: DesignTokens.cardGapLarge),

            // === 预览 ===
            _buildSectionTitle('效果预览', themeProvider),
            const SizedBox(height: DesignTokens.elementGapLarge),
            _buildPreviewCard(themeProvider),
            const SizedBox(height: DesignTokens.cardGapLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, ThemeProvider themeProvider) {
    return Text(text, style: TextStyle(
      fontSize: DesignTokens.cardTitleSize,
      fontWeight: DesignTokens.cardTitleWeight,
      color: themeProvider.textPrimary,
    ));
  }

  Widget _buildDarkModeToggle(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 22,
            color: provider.accentColor,
          ),
          const SizedBox(width: DesignTokens.elementGapLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('深色模式', style: TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w600,
                  color: provider.textPrimary,
                )),
                Text(
                  provider.isDarkMode ? '已开启深色模式' : '已开启浅色模式',
                  style: TextStyle(
                    fontSize: DesignTokens.auxSize,
                    color: provider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.isDarkMode,
            onChanged: (_) => provider.toggleDarkMode(),
            activeColor: provider.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 16,
        alignment: WrapAlignment.spaceAround,
        children: List.generate(ThemeProvider.themes.length, (index) {
          final theme = ThemeProvider.themes[index];
          final isSelected = provider.accentIndex == index;
          final displayColor = provider.isDarkMode ? theme.darkColor : theme.lightColor;
          return GestureDetector(
            onTap: () => provider.setAccentIndex(index),
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: provider.textPrimary, width: 3) : null,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: displayColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: provider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(height: DesignTokens.elementGap),
                Text(theme.name, style: TextStyle(
                  fontSize: DesignTokens.auxSize,
                  fontWeight: isSelected ? FontWeight.w600 : DesignTokens.auxWeight,
                  color: isSelected ? provider.textPrimary : provider.textAux1,
                )),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFontSizeSelector(ThemeProvider provider) {
    final sizes = [
      (label: '小', scale: 0.9, icon: Icons.text_fields),
      (label: '标准', scale: 1.0, icon: Icons.text_fields),
      (label: '大', scale: 1.15, icon: Icons.text_fields),
    ];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: sizes.map((s) {
          final isSelected = (provider.fontScale - s.scale).abs() < 0.01;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setFontScale(s.scale),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? provider.accentColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  border: isSelected ? Border.all(color: provider.accentColor, width: 2) : null,
                ),
                child: Column(
                  children: [
                    Icon(s.icon, size: s.scale * 20,
                      color: isSelected ? provider.accentColor : provider.textAux1),
                    const SizedBox(height: 4),
                    Text(s.label, style: TextStyle(
                      fontSize: DesignTokens.auxSize * s.scale,
                      fontWeight: isSelected ? FontWeight.w600 : DesignTokens.auxWeight,
                      color: isSelected ? provider.textPrimary : provider.textAux1,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: themeProvider.textSecondary),
          const SizedBox(width: DesignTokens.elementGapLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: DesignTokens.bodySize,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                )),
                Text(subtitle, style: TextStyle(
                  fontSize: DesignTokens.auxSize, color: themeProvider.textAux1,
                )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeProvider.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectColorEntry(ThemeProvider provider, BuildContext context) {
    // 展示几个示例科目颜色
    final sampleSubjects = ['语文', '数学', '英语', '体育', '美术', '科学', '音乐', '唱游'];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            onTap: () => context.push('/subject-colors'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.elementGap),
              child: Row(
                children: [
                  Icon(Icons.palette_outlined, size: 22, color: provider.textSecondary),
                  const SizedBox(width: DesignTokens.elementGapLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('科目颜色设置', style: TextStyle(
                          fontSize: DesignTokens.bodySize,
                          fontWeight: FontWeight.w600,
                          color: provider.textPrimary,
                        )),
                        Text('自定义每门课的显示颜色', style: TextStyle(
                          fontSize: DesignTokens.auxSize,
                          color: provider.textAux1,
                        )),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: provider.textAux1),
                ],
              ),
            ),
          ),
          // 颜色条预览
          const SizedBox(height: DesignTokens.elementGap),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sampleSubjects.map((subject) {
              final color = DesignTokens.subjectColors[subject] ?? provider.accentColor;
              return Tooltip(
                message: subject,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ThemeProvider provider) {
    final subjects = ['语文', '数学', '英语', '体育'];
    final periods = ['第1节', '第2节', '第3节'];
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: provider.cardColor,
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
          // 模拟 AppBar
          Row(
            children: [
              Text('课表预览', style: TextStyle(
                fontSize: DesignTokens.titleSize * provider.fontScale,
                fontWeight: DesignTokens.titleWeight,
                color: provider.textPrimary,
              )),
              const Spacer(),
              Icon(Icons.more_horiz, color: provider.textSecondary),
            ],
          ),
          const SizedBox(height: DesignTokens.elementGapLarge),
          
          // 模拟课表网格
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: provider.borderColor),
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            child: Column(
              children: List.generate(periods.length, (periodIndex) {
                return Container(
                  decoration: BoxDecoration(
                    border: periodIndex > 0 ? Border(top: BorderSide(color: provider.borderColor)) : null,
                  ),
                  child: Row(
                    children: List.generate(3, (dayIndex) {
                      final subjectIndex = (periodIndex * 3 + dayIndex) % subjects.length;
                      final subject = subjects[subjectIndex];
                      final subjectColor = DesignTokens.subjectColors[subject] ?? provider.accentColor;
                      
                      return Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: subjectColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                            border: Border.all(color: subjectColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Column(
                            children: [
                              Text(subject, style: TextStyle(
                                fontSize: DesignTokens.auxSize * provider.fontScale,
                                fontWeight: FontWeight.w700,
                                color: provider.textPrimary,
                              )),
                              const SizedBox(height: 2),
                              Container(
                                width: 24, height: 3,
                                decoration: BoxDecoration(
                                  color: subjectColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: DesignTokens.elementGapLarge),
          
          // 模拟课程卡片
          Container(
            padding: const EdgeInsets.all(DesignTokens.elementGapLarge),
            decoration: BoxDecoration(
              color: provider.cardColor,
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              border: Border(left: BorderSide(width: 4, color: provider.accentColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('语文', style: TextStyle(
                        fontSize: DesignTokens.cardTitleSize * provider.fontScale,
                        fontWeight: FontWeight.w700,
                        color: provider.textPrimary,
                      )),
                      Text('第1节 · 二年级3班', style: TextStyle(
                        fontSize: DesignTokens.auxSize * provider.fontScale,
                        color: provider.textSecondary,
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.accentColor,
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  child: Text('查看', style: TextStyle(
                    fontSize: DesignTokens.auxSize * provider.fontScale,
                    fontWeight: FontWeight.w600,
                    color: provider.isDarkMode ? const Color(0xFF1A1A1A) : DesignTokens.textPrimary,
                  )),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.elementGap),
          
          // 模拟按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.accentColor,
                    foregroundColor: provider.isDarkMode ? const Color(0xFF1A1A1A) : DesignTokens.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('添加课程', style: TextStyle(
                    fontSize: DesignTokens.bodySize * provider.fontScale,
                    fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
