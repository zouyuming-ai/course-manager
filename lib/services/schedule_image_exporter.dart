import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:course_manager/theme/design_tokens.dart';
import 'package:course_manager/models/course_schedule.dart';

/// 课表图片导出服务
/// 将课表渲染为一张图片，支持保存到相册和分享
class ScheduleImageExporter {
  static const List<String> _dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 生成课表图片的 Widget（用于 RepaintBoundary 截图）
  static Widget buildScheduleImageWidget({
    required List<CourseSchedule> schedules,
    required String studentName,
    required String semesterName,
    required Color accentColor,
    required Color bgColor,
    required double fontScale,
    List<int> days = const [1, 2, 3, 4, 5],
    List<int> periods = const [0, 1, 2, 3, 4, 5, 6, 7, 8],
  }) {
    // 调试日志
    print('[ImageExport] buildScheduleImageWidget called with ${schedules.length} schedules');
    for (final s in schedules) {
      print('[ImageExport]   ${s.subject} day=${s.dayOfWeek} period=${s.period}');
    }

    final subjectColors = <String, Color>{};
    for (final s in schedules) {
      if (!subjectColors.containsKey(s.subject)) {
        final idx = subjectColors.length % DesignTokens.subjectColors.values.length;
        subjectColors[s.subject] = DesignTokens.subjectColors.values.elementAt(idx);
      }
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(20),
      width: double.infinity,  // 关键：确保宽度约束传递给子 widget
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Text(
            '$studentName的课表 ($semesterName)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          // 表格 - 用 IntrinsicWidth 确保 FlexColumnWidth 能正确计算
          IntrinsicWidth(
            child: Table(
              border: TableBorder.all(color: DesignTokens.border, width: 1),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: FixedColumnWidth(60 * fontScale),
                for (var i = 0; i < days.length; i++)
                  i + 1: FlexColumnWidth(1),
              },
              children: [
                // 表头行
                TableRow(
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12)),
                  children: [
                    _buildHeaderCell('节次', fontScale),
                    ...days.map((d) => _buildHeaderCell(_dayNames[d - 1], fontScale)),
                  ],
                ),
                // 数据行
                ...periods.map((period) {
                  return TableRow(
                    children: [
                      _buildPeriodCell(period == 0 ? '早读' : '$period节', fontScale),
                      ...days.map((day) {
                        final course = schedules.where((s) => s.dayOfWeek == day && s.period == period).firstOrNull;
                        if (course == null) {
                          return _buildEmptyCell(fontScale);
                        }
                        final color = subjectColors[course.subject] ?? DesignTokens.textPrimary;
                        return _buildCourseCell(course.subject, course.classroom, color, fontScale);
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 底部标注
          Text(
            '由课程小管家导出',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * fontScale,
              color: DesignTokens.textAux2,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHeaderCell(String text, double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Center(
        child: Text(text, style: TextStyle(
          fontSize: 14 * fontScale,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        )),
      ),
    );
  }

  static Widget _buildPeriodCell(String text, double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Center(
        child: Text(text, style: TextStyle(
          fontSize: 12 * fontScale,
          color: DesignTokens.textAux1,
        )),
      ),
    );
  }

  static Widget _buildEmptyCell(double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: const SizedBox.shrink(),
    );
  }

  static Widget _buildCourseCell(String subject, String classroom, Color color, double fontScale) {
    // ≤4字不换行，≥5字自动换行
    final isLong = subject.length >= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(subject, textAlign: TextAlign.center,
              maxLines: isLong ? null : 1,
              overflow: isLong ? null : TextOverflow.visible,
              softWrap: isLong ? true : false,
              style: TextStyle(
              fontSize: isLong ? 10 * fontScale : 11 * fontScale,
              fontWeight: FontWeight.w600,
              color: color,
              height: isLong ? 1.3 : 1.2,
            )),
            if (classroom.isNotEmpty)
              Text(classroom, textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                fontSize: 8 * fontScale,
                color: DesignTokens.textAux1,
              )),
          ],
        ),
      ),
    );
  }

  /// 从 RepaintBoundary 截图并保存到相册（原始方法，用于屏幕上可见的 widget）
  static Future<String> captureAndSave(GlobalKey repaintBoundaryKey) async {
    print('[ImageExport] captureAndSave called');
    try {
      final boundary = repaintBoundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      print('[ImageExport] 获取到 RenderRepaintBoundary, 准备截图...');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      print('[ImageExport] 截图成功, 图片大小: ${pngBytes.length} bytes (${(pngBytes.length / 1024).toStringAsFixed(1)}KB)');

      // 保存到临时目录
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/schedule_export.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // 保存到相册
      try {
        await Gal.putImage(filePath, album: '课程小管家');
      } catch (_) {
        // 相册保存失败不影响分享功能
      }

      return filePath;
    } catch (e, stackTrace) {
      print('[ImageExport] 截图失败: $e');
      print('[ImageExport] $stackTrace');
      rethrow;
    }
  }

  /// 截图并分享
  static Future<void> captureAndShare(GlobalKey repaintBoundaryKey, String studentName) async {
    final filePath = await captureAndSave(repaintBoundaryKey);
    await Share.shareXFiles([XFile(filePath)], text: '$studentName的课表');
  }

  /// 离屏渲染 widget 为图片并保存
  /// 使用全屏透明 Overlay 承载 widget，确保 Flutter 完整渲染后再截图
  static Future<String> captureWidgetToImage({
    required BuildContext context,
    required Widget widget,
    double pixelRatio = 3.0,
  }) async {
    print('[ImageExport] captureWidgetToImage: 开始离屏渲染...');

    final globalKey = GlobalKey();
    final result = Completer<String>();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Opacity(
          // opacity 不能为 0，否则 Flutter 不渲染；用极小值实现视觉不可见
          opacity: 0.01,
          child: RepaintBoundary(
            key: globalKey,
            child: Material(
              color: Colors.transparent,
              child: Center(child: widget),
            ),
          ),
        ),
      ),
    );

    // 插入 overlay 后，等下一帧再截图
    Overlay.of(context).insert(overlayEntry);

    // 使用 addPostFrameCallback 确保在渲染帧之后执行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('[ImageExport] captureWidgetToImage: frame callback 触发');
        // 再等一帧让布局完成
        await Future.delayed(const Duration(milliseconds: 50));

        final ctx = globalKey.currentContext;
        if (ctx == null) {
          throw Exception('RepaintBoundary context 为 null！widget 可能未正确插入');
        }

        final boundary = ctx.findRenderObject()! as RenderRepaintBoundary;
        final size = boundary.size;

        print('[ImageExport] captureWidgetToImage: RenderRepaintBoundary size=$size');

        if (size.isEmpty) {
          throw Exception('RenderRepaintBoundary 尺寸为空 (${size.width}x${size.height})！');
        }

        print('[ImageExport] captureWidgetToImage: 开始 toImage...');
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();
        print('[ImageExport] captureWidgetToImage: 截图成功! ${pngBytes.length} bytes (${(pngBytes.length / 1024).toStringAsFixed(1)}KB), 图片尺寸 ${image.width}x${image.height}');

        if (pngBytes.length < 10000) {
          print('[ImageExport] ⚠️ 图片异常小！可能只截到了部分内容');
        }

        // 保存文件
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/schedule_export_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(filePath).writeAsBytes(pngBytes);

        // 保存相册
        try { await Gal.putImage(filePath, album: '课程小管家'); } catch (_) {}

        overlayEntry.remove();
        if (!result.isCompleted) result.complete(filePath);
      } catch (e, st) {
        print('[ImageExport] captureWidgetToImage 失败: $e\n$st');
        overlayEntry.remove();
        if (!result.isCompleted) result.completeError(e);
      }
    });

    return result.future;
  }
}
