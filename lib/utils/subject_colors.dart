import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 科目颜色辅助工具

/// 预设科目颜色映射（字符串形式）
/// 精简为 4+1 种颜色方案：蓝色系(主科) · 绿色系(艺体) · 橙色系(活动) · 灰色系(服务) + 强调色
const Map<String, String> presetSubjectColorHex = {
  // ── 蓝色系 — 核心主科（语数外）──
  '语文':       '#6BB6E0',
  '数学':       '#5C9CE6',
  '英语':       '#82B1FF',
  '英拓':       '#82B1FF',
  '外语':       '#82B1FF',
  '科学':       '#5C9CE6',
  '信息技术':   '#5C9CE6',
  '道德与法治': '#7BA3D8',
  '品德':       '#7BA3D8',
  '道法':       '#7BA3D8',

  // ── 绿色系 — 艺术与运动 ──
  '音乐':       '#66BB6A',
  '唱游':       '#66BB6A',
  '美术':       '#81C784',
  '写字':       '#81C784',
  '体育':       '#4DB6AC',
  '体育与健康': '#4DB6AC',
  '体活':       '#4DB6AC',
  '心理健康':   '#80CBC4',
  '阅读':       '#81C784',

  // ── 橙色系 — 活动、劳动、综合 ──
  '综合活动':   '#FFB74D',
  '快乐活动':   '#FFCC80',
  '兴活':       '#FFB74D',
  '班会':       '#FFB74D',
  '劳动':       '#FFA726',
  '劳动技术':   '#FFA726',
  '少先队活动': '#EF9A5A',

  // ── 灰色系 — 服务、安静类 ──
  '课后服务':   '#B0BEC5',
  '自习':       '#CFD8DC',
};

/// 将十六进制颜色字符串转为 Color 对象
Color hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex'; // 补全 alpha
  }
  return Color(int.parse(hex, radix: 16));
}

/// 获取科目颜色
/// 优先使用学生自定义颜色，否则使用预设颜色，最后回退到强调色
/// [customColors] 可选，传入自定义颜色映射（subject -> hex）以覆盖预设
Color getColorForSubject(String subject, String? studentId, {Map<String, String>? customColors}) {
  // 1. 优先使用自定义颜色（传入的覆盖映射）
  if (customColors != null && customColors.containsKey(subject)) {
    final hex = customColors[subject]!;
    if (hex.isNotEmpty) {
      return hexToColor(hex);
    }
  }

  // 2. 尝试从预设映射获取
  final presetHex = presetSubjectColorHex[subject];
  if (presetHex != null) {
    return hexToColor(presetHex);
  }

  // 3. 回退到设计系统中的科目颜色
  final designColor = DesignTokens.subjectColors[subject];
  if (designColor != null) {
    return designColor;
  }

  // 4. 最终回退到强调色
  return DesignTokens.accent;
}

/// 获取科目颜色的十六进制字符串
String getHexForSubject(String subject) {
  return presetSubjectColorHex[subject] ?? '#FFC857';
}

/// 获取所有预设科目名称列表
List<String> getAllSubjects() {
  return presetSubjectColorHex.keys.toList();
}
