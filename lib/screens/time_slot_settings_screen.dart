import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';
import '../providers/time_slot_provider.dart';
import '../providers/semester_provider.dart';
import '../models/time_slot.dart';

/// 时间点配置主页
/// 显示当前学期的所有时间点（早读、第1~8节），支持新增、编辑、删除、重置默认
class TimeSlotSettingsScreen extends StatefulWidget {
  const TimeSlotSettingsScreen({super.key});

  @override
  State<TimeSlotSettingsScreen> createState() => _TimeSlotSettingsScreenState();
}

class _TimeSlotSettingsScreenState extends State<TimeSlotSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // 设置当前学期
    final semesterProvider = context.read<SemesterProvider>();
    final timeSlotProvider = context.read<TimeSlotProvider>();
    if (semesterProvider.activeSemester != null) {
      timeSlotProvider.setSemester(semesterProvider.activeSemester!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeSlotProvider = context.watch<TimeSlotProvider>();
    final semesterProvider = context.watch<SemesterProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;

    final activeSemester = semesterProvider.activeSemester;

    if (activeSemester == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bg,
        appBar: AppBar(title: const Text('时间点配置')),
        body: const Center(child: Text('请先添加学期')),
      );
    }

    final timeSlots = timeSlotProvider.timeSlots;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('时间点配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置默认',
            onPressed: () => _resetDefaults(context, activeSemester.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.pageMargin),
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(DesignTokens.cardGap),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Text(
              '配置上下课时间后，课表将显示对应时间节点，导出和提醒功能也会使用此处设置的时间。',
              style: TextStyle(
                fontSize: DesignTokens.auxSize,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.cardGap),

          // 时间点列表
          if (timeSlots.isEmpty)
            _buildEmptyState(context, activeSemester.id)
          else
            ...timeSlots.map((ts) => _buildTimeSlotCard(context, ts)),

          const SizedBox(height: DesignTokens.cardGap),

          // 添加按钮
          ElevatedButton.icon(
            onPressed: () => context.push('/time-slots/edit'),
            icon: const Icon(Icons.add),
            label: const Text('添加时间点'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.cardGap),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String semesterId) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardGapLarge),
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: DesignTokens.textAux2,
          ),
          const SizedBox(height: DesignTokens.elementGap),
          Text(
            '尚未配置时间点',
            style: TextStyle(
              fontSize: DesignTokens.bodySize,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.elementGap),
          ElevatedButton(
            onPressed: () => _initDefaults(context, semesterId),
            child: const Text('使用默认时间点'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(BuildContext context, TimeSlot ts) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.elementGap),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DesignTokens.accent,
          child: Text(
            '${ts.period == 0 ? '早读' : ts.period}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(ts.displayLabel),
        subtitle: Text(ts.displayTime),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.push('/time-slots/edit?slotId=${ts.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined, size: 20, color: Colors.red),
              onPressed: () => _deleteTimeSlot(context, ts.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initDefaults(BuildContext context, String semesterId) async {
    final timeSlotProvider = context.read<TimeSlotProvider>();
    await timeSlotProvider.initDefaultTimeSlots(semesterId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已初始化默认时间点')),
      );
    }
  }

  Future<void> _resetDefaults(BuildContext context, String semesterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置为默认'),
        content: const Text('将清空所有自定义配置，恢复为默认时间点（白鹤小学作息）。确认？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('确认')),
        ],
      ),
    );
    if (confirmed != true) return;

    final timeSlotProvider = context.read<TimeSlotProvider>();
    // 删除现有时间点
    for (final ts in timeSlotProvider.timeSlots) {
      await timeSlotProvider.deleteTimeSlot(ts.id);
    }
    // 初始化默认
    await timeSlotProvider.initDefaultTimeSlots(semesterId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置为默认时间点')),
      );
    }
  }

  Future<void> _deleteTimeSlot(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定删除该时间点？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;

    final timeSlotProvider = context.read<TimeSlotProvider>();
    await timeSlotProvider.deleteTimeSlot(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    }
  }
}
