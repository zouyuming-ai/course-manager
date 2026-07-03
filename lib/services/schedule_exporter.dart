import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docx_dart/docx_dart.dart' as docx;
import 'package:course_manager/models/course_schedule.dart';
import 'package:course_manager/models/time_slot.dart';
import 'package:flutter/foundation.dart';

/// 课表导出工具
/// 生成 Excel、Markdown、HTML(Word) 格式的课表文件
class ScheduleExporter {
  static const List<String> _dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 生成课表数据矩阵（行=节次，列=星期）
  /// [timeSlots] 可选，若提供则节次标签包含时间段（如 "第一节 (8:30-9:10)"）
  static List<List<String>> buildScheduleMatrix(
    List<CourseSchedule> schedules,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) {
    // 调试日志
    print('[ScheduleExporter] buildScheduleMatrix called');
    print('[ScheduleExporter] schedules.length=${schedules.length}, days=$days, periods=$periods');
    for (final s in schedules) {
      print('[ScheduleExporter] 课程: ${s.subject} day=${s.dayOfWeek} period=${s.period} weekType="${s.weekType}"');
      // 检查是否在有效范围内
      final dayValid = days.contains(s.dayOfWeek);
      final periodValid = periods.contains(s.period);
      print('[ScheduleExporter]   day在范围内? $dayValid, period在范围内? $periodValid');
    }

    final matrix = <List<String>>[];
    for (final period in periods) {
      final row = <String>[];
      // 节次标签：优先从 timeSlots 读取，否则用默认标签
      String periodLabel;
      if (timeSlots != null) {
        final ts = timeSlots.where((t) => t.period == period).firstOrNull;
        if (ts != null) {
          periodLabel = '${ts.displayLabel} (${ts.displayTime})';
        } else {
          periodLabel = period == 0 ? '早读' : '第$period节';
        }
      } else {
        periodLabel = period == 0 ? '早读' : '第$period节';
      }
      row.add(periodLabel);
      for (final day in days) {
        final course = schedules.where((s) => s.dayOfWeek == day && s.period == period).firstOrNull;
        if (course != null) {
          row.add('${course.subject}${course.classroom.isNotEmpty ? '(${course.classroom})' : ''}');
        } else {
          row.add('');
        }
      }
      matrix.add(row);
    }
    return matrix;
  }

  /// ---- Excel 导出 ----

  /// 生成 Excel 文件并返回路径
  static Future<String> exportExcel(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['课表'];

    // 删除默认 Sheet（Excel.createExcel 会创建名为 Sheet1 的默认 sheet）
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 标题行
    final titleRow = [TextCellValue(studentName + '的课表($semesterName)')];
    sheet.insertRowIterables(titleRow, 0);

    // 表头行（节次 + 星期）
    final headerRow = [TextCellValue('节次')];
    for (final day in days) {
      headerRow.add(TextCellValue(_dayNames[day - 1]));
    }
    sheet.insertRowIterables(headerRow, 1);

    // 数据行
    final matrix = buildScheduleMatrix(schedules, days, periods, timeSlots: timeSlots);
    for (var i = 0; i < matrix.length; i++) {
      sheet.insertRowIterables(matrix[i].map((cell) => TextCellValue(cell)).toList(), i + 2);
    }

    // 设置列宽
    for (var col = 0; col <= days.length; col++) {
      sheet.setColumnWidth(col, 18);
    }

    // 保存文件
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${studentName}_课表.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return filePath;
  }

  /// ---- Markdown 导出 ----

  /// 生成 Markdown 文本
  static String generateMarkdown(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# $studentName的课表($semesterName)');
    buffer.writeln();

    // 表头
    var header = '| 节次 |';
    for (final day in days) {
      header += ' ${_dayNames[day - 1]} |';
    }
    buffer.writeln(header);

    // 分隔线
    var separator = '| --- |';
    for (final _ in days) {
      separator += ' --- |';
    }
    buffer.writeln(separator);

    // 数据行
    final matrix = buildScheduleMatrix(schedules, days, periods, timeSlots: timeSlots);
    for (final row in matrix) {
      final line = row.map((cell) => cell.isEmpty ? ' ' : cell).join(' | ');
      buffer.writeln('| $line |');
    }

    buffer.writeln();
    buffer.writeln('> 由课程小管家导出');
    return buffer.toString();
  }

  /// 导出 Markdown 文件并返回路径
  static Future<String> exportMarkdown(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${studentName}_课表.md';
    final file = File(filePath);
    await file.writeAsString(generateMarkdown(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots));
    return filePath;
  }

  /// ---- Word(HTML) 导出 ----

  /// 生成 HTML 格式的课表（Word 可以打开 HTML 文件）
  static String generateHtml(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) {
    final matrix = buildScheduleMatrix(schedules, days, periods, timeSlots: timeSlots);

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<meta charset="utf-8">');
    buffer.writeln('<title>$studentName的课表</title>');
    buffer.writeln('<style>');
    buffer.writeln('  body { font-family: "Microsoft YaHei", "SimHei", sans-serif; padding: 20px; }');
    buffer.writeln('  h1 { text-align: center; color: #333; }');
    buffer.writeln('  table { border-collapse: collapse; width: 100%; margin: 20px auto; }');
    buffer.writeln('  th, td { border: 1px solid #ddd; padding: 10px 8px; text-align: center; font-size: 14px; }');
    buffer.writeln('  th { background-color: #4CAF50; color: white; font-weight: bold; }');
    buffer.writeln('  td.has-course { background-color: #E8F5E9; font-weight: 500; }');
    buffer.writeln('  .footer { text-align: center; color: #999; font-size: 12px; margin-top: 20px; }');
    buffer.writeln('</style></head><body>');
    buffer.writeln('<h1>$studentName的课表 ($semesterName)</h1>');
    buffer.writeln('<table>');

    // 表头
    buffer.writeln('<tr><th>节次</th>');
    for (final day in days) {
      buffer.writeln('<th>${_dayNames[day - 1]}</th>');
    }
    buffer.writeln('</tr>');

    // 数据行
    for (final row in matrix) {
      buffer.writeln('<tr>');
      for (var i = 0; i < row.length; i++) {
        final cell = row[i];
        final hasCourse = i > 0 && cell.isNotEmpty;
        final cls = hasCourse ? ' class="has-course"' : '';
        buffer.writeln('<td$cls>${cell.isEmpty ? '&nbsp;' : cell}</td>');
      }
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('<div class="footer">由课程小管家导出</div>');
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  /// 导出 Word(.doc) 格式文件（实际是 HTML，Word可以正常打开）并返回路径
  static Future<String> exportWord(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${studentName}_课表.doc';
    final file = File(filePath);
    await file.writeAsString(generateHtml(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots));
    return filePath;
  }

  /// ---- 真正的 Word(.docx) 导出 ----

  /// 生成真正的 .docx 文件（使用 docx_dart 包）
  static Future<String> exportDocx(
    List<CourseSchedule> schedules,
    String studentName,
    String semesterName,
    List<int> days,
    List<int> periods, {
    List<TimeSlot>? timeSlots,
  }) async {
    try {
      final document = docx.loadDocxDocument();
      final matrix = buildScheduleMatrix(schedules, days, periods, timeSlots: timeSlots);

      // 添加标题
      document.addHeading(text: '$studentName的课表 ($semesterName)', level: 1);

      // 添加表格（行数 = 表头1行 + 数据行数，列数 = 星期数 + 1节次列）
      final table = document.addTable(
        matrix.length + 1,
        days.length + 1,
        style: 'Table Grid',
      );

      // 表头行
      table.cell(0, 0).text = '节次';
      for (var j = 0; j < days.length; j++) {
        table.cell(0, j + 1).text = _dayNames[days[j] - 1];
      }

      // 数据行
      for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < matrix[i].length; j++) {
          table.cell(i + 1, j).text = matrix[i][j];
        }
      }

      // 添加页脚说明
      document.addParagraph(text: '由课程小管家导出');

      // 保存文件
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${studentName}_课表.docx';
      document.save(filePath);

      return filePath;
    } catch (e) {
      // 如果 docx 生成失败，降级为 HTML 格式 .doc
      debugPrint('⚠️ docx 生成失败，降级为 HTML: $e');
      return exportWord(schedules, studentName, semesterName, days, periods, timeSlots: timeSlots);
    }
  }

  /// ---- 分享 ----

  /// 通过系统分享面板分享文件
  static Future<void> shareFile(String filePath, String subjectName) async {
    await Share.shareXFiles([XFile(filePath)], text: '$subjectName的课表');
  }

  /// 分享文本内容
  static Future<void> shareText(String text, String subjectName) async {
    await Share.share(text, subject: '$subjectName的课表');
  }
}
