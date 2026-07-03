import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/utils/app_version.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/time_slot_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/providers/backpack_provider.dart';

/// 设置主页
/// 包含：学期管理、主题设置（预留）、假期日历（预留）、导出/分享（预留）、关于/版本信息

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.cardGap,
        ),
        child: Column(
          children: [
            // 学期管理
            _SettingsRow(
              icon: Icons.school_outlined,
              title: '学期管理',
              onTap: () => context.push('/tabs/settings/semester'),
            ),

            // 时间点配置
            _SettingsRow(
              icon: Icons.access_time_outlined,
              title: '时间点配置',
              subtitle: '设置上下课时间',
              onTap: () => context.push('/time-slots'),
            ),

            // 预置默认课表
            _SettingsRow(
              icon: Icons.school_outlined,
              title: '预置默认课表',
              subtitle: '一键导入预置课程表和时间点',
              onTap: () => _showPresetConfirmDialog(context),
            ),

            // 家庭作业
            _SettingsRow(
              icon: Icons.assignment_outlined,
              title: '家庭作业',
              onTap: () => context.push('/homework'),
            ),

            // 主题设置
            _SettingsRow(
              icon: Icons.palette_outlined,
              title: '主题外观',
              onTap: () => context.push('/theme'),
            ),

            // 假期日历
            _SettingsRow(
              icon: Icons.beach_access_outlined,
              title: '假期日历',
              onTap: () => context.push('/calendar'),
            ),

            // 一键复制课表
            _SettingsRow(
              icon: Icons.copy_all_outlined,
              title: '一键复制课表',
              onTap: () => context.push('/schedule/copy'),
            ),

            // 导出/分享
            _SettingsRow(
              icon: Icons.share_outlined,
              title: '导出/分享',
              onTap: () => context.push('/export'),
            ),

            const Divider(height: DesignTokens.cardGapLarge),

            // 关于/版本信息
            _SettingsRow(
              icon: Icons.info_outlined,
              title: '关于课程小管家',
              subtitle: AppVersion.fullVersion,
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('课程小管家'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：${AppVersion.fullVersion}'),
            SizedBox(height: DesignTokens.elementGap),
            Text('让每个书包都准备就绪', style: TextStyle(
              fontWeight: FontWeight.w600,
              color: DesignTokens.accent,
            )),
            SizedBox(height: DesignTokens.elementGap),
            Text('课程小管家是一款帮助家长管理孩子课表、书包准备和提醒事项的工具App。支持课表导入、自动生成书包清单、自定义提醒通知等功能。'),
            SizedBox(height: DesignTokens.elementGap),
            Row(
              children: [
                Text('开发者：', style: TextStyle(
                  fontSize: DesignTokens.auxSize,
                  color: DesignTokens.textAux1,
                )),
                Text('奇妙设计（Magidea Design）团队', style: TextStyle(
                  fontSize: DesignTokens.auxSize,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 预置默认课表确认对话框
  void _showPresetConfirmDialog(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final timeSlotProvider = context.read<TimeSlotProvider>();
    final studentProvider = context.read<StudentProvider>();
    final semesterProvider = context.read<SemesterProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('预置默认课表'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将导入以下数据：'),
            SizedBox(height: DesignTokens.elementGap),
            Text('• 作息时间（9个时间段）'),
            Text('• 完整课程表（45门课）'),
            SizedBox(height: DesignTokens.elementGap),
            Text('⚠️ 注意：如果已有课表数据，将被覆盖。', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              final activeStudent = studentProvider.activeStudent;
              if (activeStudent == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ 请先添加学生信息')),
                  );
                }
                return;
              }
              
              final activeSemester = semesterProvider.activeSemester;
              if (activeSemester == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ 请先创建学期')),
                  );
                }
                return;
              }

              // 显示加载指示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // 1. 初始化时间点
                await timeSlotProvider.initDefaultTimeSlots(activeSemester.id);
                timeSlotProvider.setSemester(activeSemester.id);

                // 2. 初始化课表
                await scheduleProvider.initBaiheDefaultSchedules(activeStudent.id, activeSemester.id);

                // 3. 自动生成明天书包建议
                final backpackProvider = context.read<BackpackProvider>();
                backpackProvider.generateSuggestionsForTomorrow(
                  activeStudent.id,
                  activeSemester.id,
                  scheduleProvider.schedules,
                );
                
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // 关闭 loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 预置课表已导入成功！'), duration: Duration(seconds: 3)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // 关闭 loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ 预置失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定导入'),
          ),
        ],
      ),
    );
  }
}

/// 设置行组件
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.elementGap),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 24,
          color: DesignTokens.textPrimary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: DesignTokens.bodySize,
            fontWeight: DesignTokens.bodyWeight,
            color: DesignTokens.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: DesignTokens.auxSize,
                  fontWeight: DesignTokens.auxWeight,
                  color: DesignTokens.textAux2,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: DesignTokens.textAux1,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
      ),
    );
  }
}
