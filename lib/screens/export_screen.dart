import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/providers/theme_provider.dart';
import 'package:course_manager/providers/student_provider.dart';
import 'package:course_manager/providers/semester_provider.dart';
import 'package:course_manager/providers/schedule_provider.dart';
import 'package:course_manager/providers/time_slot_provider.dart';
import 'package:course_manager/services/schedule_exporter.dart';
import 'package:course_manager/services/schedule_image_exporter.dart';
import 'package:course_manager/models/course_schedule.dart';
import 'package:course_manager/models/time_slot.dart';

/// S15 导出/分享页面（重构版）
/// 支持：图片导出、Excel导出、Markdown导出、Word导出、微信/系统分享
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  /// 获取星期几的中文名称
  String _getDayName(int dayOfWeek) {
    const days = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};
    return days[dayOfWeek] ?? dayOfWeek.toString();
  }

  /// 获取节次名称
  String _getPeriodName(int period) {
    if (period == 0) return '早读';
    return '第$period节';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.accentColor;
    final bgColor = themeProvider.bgColor;
    final fontScale = themeProvider.fontScale;

    final studentProvider = context.watch<StudentProvider>();
    final semesterProvider = context.watch<SemesterProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final timeSlotProvider = context.watch<TimeSlotProvider>();

    final activeStudent = studentProvider.activeStudent;
    final activeSemester = semesterProvider.activeSemester;

    if (activeStudent == null || activeSemester == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('导出/分享')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: DesignTokens.textAux3),
              const SizedBox(height: DesignTokens.cardGap),
              const Text('请先设置学生和学期后再导出课表',
                style: TextStyle(color: DesignTokens.textSecondary)),
            ],
          ),
        ),
      );
    }

    final schedules = scheduleProvider.getSchedulesForStudent(activeStudent.id, activeSemester.id);

    // 自动去重：同一(星期+节次+科目)只保留一条（优先保留weekType="ALL"的）
    final dedupedSchedules = <CourseSchedule>[];
    final seenKeys = <String>{};
    for (final s in schedules) {
      final key = '${s.dayOfWeek}_${s.period}_${s.subject}';
      if (seenKeys.contains(key)) {
        // 如果已存在，检查是否需要替换（用ALL替换A/B）
        final existingIndex = dedupedSchedules.indexWhere((e) =>
          '${e.dayOfWeek}_${e.period}_${e.subject}' == key);
        if (existingIndex >= 0 && s.weekType == 'ALL' && dedupedSchedules[existingIndex].weekType != 'ALL') {
          dedupedSchedules[existingIndex] = s; // 用ALL版本替换
        }
        // 否则跳过重复记录
      } else {
        seenKeys.add(key);
        dedupedSchedules.add(s);
      }
    }

    // 如果有去重，显示提示
    final effectiveSchedules = dedupedSchedules;

    final days = [1, 2, 3, 4, 5];
    final periods = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    // 读取时间点配置，导出时带上时间节点
    final timeSlots = timeSlotProvider.timeSlots;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text('导出/分享')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.pageMargin,
          vertical: DesignTokens.cardGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 课表预览（用于截图）
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: ScheduleImageExporter.buildScheduleImageWidget(
                schedules: effectiveSchedules,
                studentName: activeStudent.name,
                semesterName: activeSemester.name,
                accentColor: accentColor,
                bgColor: bgColor,
                fontScale: fontScale,
                days: days,
                periods: periods,
              ),
            ),

            const SizedBox(height: DesignTokens.cardGapLarge),

            // 导出选项
            Text('导出格式', style: TextStyle(
              fontSize: DesignTokens.cardTitleSize * fontScale,
              fontWeight: DesignTokens.cardTitleWeight,
              color: DesignTokens.textPrimary,
            )),
            const SizedBox(height: DesignTokens.elementGapLarge),

            // 保存为图片
            _buildExportCard(
              icon: Icons.image_outlined,
              title: '保存为图片',
              subtitle: '保存到相册，可直接分享到微信',
              accentColor: accentColor,
              fontScale: fontScale,
              onTap: () => _exportImage(
                effectiveSchedules,
                activeStudent.name,
                activeSemester.name,
                accentColor,
                bgColor,
                fontScale,
                days,
                periods,
              ),
            ),
            const SizedBox(height: DesignTokens.elementGap),

            // 导出 Excel
            _buildExportCard(
              icon: Icons.table_chart_outlined,
              title: '导出Excel',
              subtitle: '生成.xlsx文件，可用Excel/WPS编辑',
              accentColor: accentColor,
              fontScale: fontScale,
              onTap: () => _exportExcel(effectiveSchedules, activeStudent.name, activeSemester.name, days, periods, timeSlots),
            ),
            const SizedBox(height: DesignTokens.elementGap),

            // 导出 Word
            _buildExportCard(
              icon: Icons.description_outlined,
              title: '导出Word',
              subtitle: '生成.docx文件，可用Word/WPS编辑',
              accentColor: accentColor,
              fontScale: fontScale,
              onTap: () => _exportDocx(effectiveSchedules, activeStudent.name, activeSemester.name, days, periods, timeSlots),
            ),
            const SizedBox(height: DesignTokens.elementGap),

            // 导出 Markdown
            _buildExportCard(
              icon: Icons.code_outlined,
              title: '导出Markdown',
              subtitle: '生成.md文件，适合文本编辑和分享',
              accentColor: accentColor,
              fontScale: fontScale,
              onTap: () => _exportMarkdown(effectiveSchedules, activeStudent.name, activeSemester.name, days, periods, timeSlots),
            ),
            const SizedBox(height: DesignTokens.elementGap),

            // 分享到微信/其他
            _buildExportCard(
              icon: Icons.share_outlined,
              title: '分享',
              subtitle: '通过微信/QQ等App分享课表',
              accentColor: accentColor,
              fontScale: fontScale,
              onTap: () => _shareSchedule(effectiveSchedules, activeStudent.name, activeSemester.name, days, periods, timeSlots),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required double fontScale,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: DesignTokens.card,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: ListTile(
        leading: Icon(icon, size: 24, color: accentColor),
        title: Text(title, style: TextStyle(
          fontSize: DesignTokens.bodySize * fontScale,
          fontWeight: DesignTokens.bodyWeight,
          color: DesignTokens.textPrimary,
        )),
        subtitle: Text(subtitle, style: TextStyle(
          fontSize: DesignTokens.auxSize * fontScale,
          color: DesignTokens.textAux1,
        )),
        trailing: _isExporting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.chevron_right, size: 20, color: DesignTokens.textAux1),
        onTap: _isExporting ? null : onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
      ),
    );
  }

  // ---- 导出操作 ----

  Future<void> _exportImage(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    Color accentColor,
    Color bgColor,
    double fontScale,
    List<int> days,
    List<int> periods,
  ) async {
    setState(() => _isExporting = true);
    try {
      print('[ExportScreen] _exportImage called, 使用屏幕 RepaintBoundary 截图...');
      
      // 先滚动到课表预览区域，确保它在可视范围内
      final ctx = _repaintBoundaryKey.currentContext;
      if (ctx != null) {
        print('[ExportScreen] 滚动到 RepaintBoundary 位置...');
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
        // 等待滚动和渲染完成
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 直接截取屏幕上已渲染的 RepaintBoundary（最可靠的方式）
      final filePath = await ScheduleImageExporter.captureAndSave(_repaintBoundaryKey);
      
      print('[ExportScreen] ✅ 图片导出成功: $filePath');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('课表图片已保存到相册'),
            backgroundColor: DesignTokens.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      print('[ExportScreen] ❌ 图片导出失败: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel(
    List<CourseSchedule> schedules, String studentName, String semesterName,
    List<int> days, List<int> periods,
    List<TimeSlot> timeSlots,
  ) async {
    setState(() => _isExporting = true);
    try {
      final filePath = await ScheduleExporter.exportExcel(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots);
      await ScheduleExporter.shareFile(filePath, studentName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDocx(
    List<CourseSchedule> schedules, String studentName, String semesterName,
    List<int> days, List<int> periods,
    List<TimeSlot> timeSlots,
  ) async {
    setState(() => _isExporting = true);
    try {
      final filePath = await ScheduleExporter.exportDocx(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots);
      await ScheduleExporter.shareFile(filePath, studentName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word文件已导出'),
            backgroundColor: DesignTokens.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportMarkdown(
    List<CourseSchedule> schedules, String studentName, String semesterName,
    List<int> days, List<int> periods,
    List<TimeSlot> timeSlots,
  ) async {
    setState(() => _isExporting = true);
    try {
      final filePath = await ScheduleExporter.exportMarkdown(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots);
      await ScheduleExporter.shareFile(filePath, studentName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _shareSchedule(
    List<CourseSchedule> schedules, String studentName, String semesterName,
    List<int> days, List<int> periods,
    List<TimeSlot> timeSlots,
  ) async {
    setState(() => _isExporting = true);
    try {
      // 先截图生成图片，再通过系统分享面板分享
      final filePath = await ScheduleImageExporter.captureAndSave(_repaintBoundaryKey);
      await ScheduleExporter.shareFile(filePath, studentName);
    } catch (e) {
      // 图片分享失败时退回文本分享
      try {
        final md = ScheduleExporter.generateMarkdown(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots);
        await ScheduleExporter.shareText(md, studentName);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享失败'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
