import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 应用主题配置 - 课程小管家
/// 基于 soft-cream-yellow-storybook 设计风格

class AppTheme {
  /// 亮色主题
  static ThemeData lightTheme = ThemeData(
    // 字体：优先使用 SarasaGothicSC，回退到系统中文字体
    fontFamily: 'SarasaGothicSC',

    // 基于 #FFC857 种子色的 ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: DesignTokens.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: DesignTokens.accent,
      onPrimary: DesignTokens.textPrimary,
      surface: DesignTokens.bg,
      onSurface: DesignTokens.textPrimary,
      secondary: DesignTokens.pillBg,
      onSecondary: DesignTokens.textSecondary,
    ),

    // 全局背景色
    scaffoldBackgroundColor: DesignTokens.bg,

    // AppBar 主题
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: DesignTokens.bg,
      foregroundColor: DesignTokens.textPrimary,
      titleTextStyle: TextStyle(
        fontFamily: 'SarasaGothicSC',
        fontSize: DesignTokens.titleSize,
        fontWeight: DesignTokens.titleWeight,
        color: DesignTokens.textPrimary,
      ),
    ),

    // Card 主题
    cardTheme: CardTheme(
      elevation: 0,
      color: DesignTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.pageMargin,
        vertical: DesignTokens.cardGap / 2,
      ),
    ),

    // ElevatedButton 主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.accent,
        foregroundColor: DesignTokens.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
        ),
        textStyle: const TextStyle(
          fontFamily: 'SarasaGothicSC',
          fontSize: DesignTokens.bodySize,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),

    // TextButton 主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.textSecondary,
        textStyle: const TextStyle(
          fontFamily: 'SarasaGothicSC',
          fontSize: DesignTokens.bodySize,
          fontWeight: DesignTokens.bodyWeight,
        ),
      ),
    ),

    // InputDecoration 主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        borderSide: const BorderSide(color: DesignTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        borderSide: const BorderSide(color: DesignTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        borderSide: const BorderSide(color: DesignTokens.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      hintStyle: const TextStyle(
        color: DesignTokens.textAux2,
        fontSize: DesignTokens.bodySize,
      ),
    ),

    // Divider 主题
    dividerTheme: const DividerThemeData(
      color: DesignTokens.border,
      thickness: 1,
      space: 1,
    ),

    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DesignTokens.bg,
      elevation: 0,
    ),

    // 对话框主题
    dialogTheme: DialogTheme(
      backgroundColor: DesignTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadiusLarge),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'SarasaGothicSC',
        fontSize: DesignTokens.titleSize,
        fontWeight: DesignTokens.titleWeight,
        color: DesignTokens.textPrimary,
      ),
    ),

    // Snackbar 主题
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DesignTokens.textPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'SarasaGothicSC',
        fontSize: DesignTokens.bodySize,
        color: DesignTokens.card,
      ),
    ),

    // 页面过渡动画
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
