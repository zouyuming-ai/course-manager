import 'package:flutter/material.dart';

/// 设计系统 Token - 课程小管家
/// 设计规格：390×844 / soft-cream-yellow-storybook 风格

class DesignTokens {
  // ========== 颜色系统 ==========

  /// 主背景色 - 柔奶油黄
  static const Color bg = Color(0xFFFFFAF0);

  /// 卡片背景色 - 纯白
  static const Color card = Color(0xFFFFFFFF);

  /// 强调色 - 活力琥珀黄
  static const Color accent = Color(0xFFFFC857);

  /// 胶囊/药丸背景色 - 淡麦芽黄
  static const Color pillBg = Color(0xFFF5EED4);

  /// 主文字色 - 深棕黑
  static const Color textPrimary = Color(0xFF2D2A26);

  /// 次文字色 - 暖棕
  static const Color textSecondary = Color(0xFF5C5147);

  /// 辅助文字色层级
  static const Color textAux1 = Color(0xFF888888);
  static const Color textAux2 = Color(0xFF999999);
  static const Color textAux3 = Color(0xFFBBBBBB);

  /// 边框色 - 暖金边
  static const Color border = Color(0xFFF5E5BD);

  // ========== 科目颜色 ==========
  // 精简为 4+1 种颜色方案，避免课表过于花哨
  //   蓝色系(语数外) · 绿色系(音美体) · 橙色系(活动劳动) · 灰色系(服务安静) + 特殊强调
  //   原则：同类同色 / 视觉清爽 / 一目了然

  static const Map<String, Color> subjectColors = {
    // ── 蓝色系 — 核心主科（语数外）──
    '语文':       Color(0xFF6BB6E0),  // 天蓝 — 清晰稳重
    '数学':       Color(0xFF5C9CE6),  // 钢蓝 — 逻辑理性
    '英语':       Color(0xFF82B1FF),  // 浅蓝 — 开放交流
    '英拓':       Color(0xFF82B1FF),  // 浅蓝（语言拓展）
    '外语':       Color(0xFF82B1FF),  // 浅蓝
    '科学':       Color(0xFF5C9CE6),  // 钢蓝 — 理性探索
    '信息技术':   Color(0xFF5C9CE6),  // 钢蓝 — 科技数字
    '道德与法治': Color(0xFF7BA3D8),  // 柔蓝 — 人文稳重
    '品德':       Color(0xFF7BA3D8),  // 柔蓝
    '道法':       Color(0xFF7BA3D8),  // 柔蓝（简称）

    // ── 绿色系 — 艺术与运动 ──
    '音乐':       Color(0xFF66BB6A),  // 草绿 — 活泼
    '唱游':       Color(0xFF66BB6A),  // 草绿
    '美术':       Color(0xFF81C784),  // 嫩绿 — 创意
    '写字':       Color(0xFF81C784),  // 嫩绿
    '体育':       Color(0xFF4DB6AC),  // 青绿 — 自然活力
    '体育与健康': Color(0xFF4DB6AC),  // 青绿
    '体活':       Color(0xFF4DB6AC),  // 青绿
    '心理健康':   Color(0xFF80CBC4),  // 薄荷青 — 舒缓
    '阅读':       Color(0xFF81C784),  // 嫩绿 — 沉浸

    // ── 橙色系 — 活动、劳动、综合 ──
    '综合活动':   Color(0xFFFFB74D),  // 暖橙 — 综合
    '快乐活动':   Color(0xFFFFCC80),  // 浅橙 — 欢快
    '兴活':       Color(0xFFFFB74D),  // 暖橙
    '班会':       Color(0xFFFFB74D),  // 暖橙 — 组织
    '劳动':       Color(0xFFFFA726),  // 深橙 — 实践
    '劳动技术':   Color(0xFFFFA726),  // 深橙
    '少先队活动': Color(0xFFEF9A5A),  // 杏色 — 组织

    // ── 灰色系 — 服务、安静类 ──
    '课后服务':   Color(0xFFB0BEC5),  // 蓝灰 — 安静沉稳
    '自习':       Color(0xFFCFD8DC),  // 浅灰 — 安静自主

    // ── 特殊强调（放学等用户自定义）──
    // 不预设，使用 accent 色 (#FFC857) 作为回退
  };

  // ========== 状态颜色 ==========

  /// 成功/完成状态
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  /// 待处理状态
  static const Color pendingBg = Color(0xFFFFF3E0);
  static const Color pendingText = Color(0xFFE65100);

  /// 周末/休息状态
  static const Color weekendBg = Color(0xFFFFEBEE);
  static const Color weekendText = Color(0xFFC62828);

  // ========== 字号系统 ==========

  /// Hero/引导标题 - 28px / w700
  static const double heroSize = 28;
  static const FontWeight heroWeight = FontWeight.w700;

  /// 页面标题 - 18px / w600
  static const double titleSize = 18;
  static const FontWeight titleWeight = FontWeight.w600;

  /// 卡片标题 - 16~17px / w600
  static const double cardTitleSize = 16;
  static const double cardTitleSizeLarge = 17;
  static const FontWeight cardTitleWeight = FontWeight.w600;

  /// 正文 - 14px / w400
  static const double bodySize = 14;
  static const FontWeight bodyWeight = FontWeight.w400;

  /// 辅助文字 - 12~13px / w400
  static const double auxSize = 12;
  static const double auxSizeLarge = 13;
  static const FontWeight auxWeight = FontWeight.w400;

  /// 标签文字 - 10~11px / w400
  static const double tagSize = 10;
  static const double tagSizeLarge = 11;
  static const FontWeight tagWeight = FontWeight.w400;

  // ========== 圆角系统 ==========

  /// 页面级圆角
  static const double screenRadius = 40;

  /// 卡片圆角
  static const double cardRadius = 16;
  static const double cardRadiusLarge = 24;

  /// 按钮圆角
  static const double buttonRadius = 10;
  static const double buttonRadiusLarge = 14;

  /// 圆形元素
  static const double circleRadius = 20;
  static const double circleRadiusLarge = 26;

  /// 胶囊/药丸圆角
  static const double pillRadius = 36;
  static const double pillRadiusSmall = 26;

  // ========== 间距系统 ==========

  /// 页面边距
  static const double pageMargin = 20;

  /// 卡片间距
  static const double cardGap = 12;
  static const double cardGapLarge = 16;

  /// 卡片内边距
  static const double cardPadding = 16;

  /// 元素间距
  static const double elementGap = 8;
  static const double elementGapLarge = 12;

  /// TabBar 高度
  static const double tabBarHeight = 95;

  /// NavBar 高度
  static const double navBarHeight = 56;

  /// 状态栏高度
  static const double statusBarHeight = 54;
}
