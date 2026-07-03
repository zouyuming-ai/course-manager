import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/design_tokens.dart';

/// 主题偏好设置 Provider
/// 管理强调色、字体大小、显示设置、深色模式
class ThemeProvider extends ChangeNotifier {
  late Box _box;

  static const _keyAccentIndex = 'theme_accentIndex';
  static const _keyFontScale = 'theme_fontScale';
  static const _keyShowWeekend = 'theme_showWeekend';
  static const _keyShowClassTime = 'theme_showClassTime';
  static const _keyDarkMode = 'theme_darkMode';

  /// 10 种预设主题色板（浅色 + 深色）
  static const List<({String name, Color lightColor, Color lightBg, Color darkColor, Color darkBg})> themes = [
    // 0: 奶油黄
    (name: '奶油黄', lightColor: Color(0xFFFFC857), lightBg: Color(0xFFFFFAF0), darkColor: Color(0xFFFFC857), darkBg: Color(0xFF1A1A1A)),
    // 1: 蜜桃粉
    (name: '蜜桃粉', lightColor: Color(0xFFFF6B9D), lightBg: Color(0xFFFFF5F8), darkColor: Color(0xFFFF6B9D), darkBg: Color(0xFF1A1215)),
    // 2: 天空蓝
    (name: '天空蓝', lightColor: Color(0xFF6BB6E0), lightBg: Color(0xFFF5FAFE), darkColor: Color(0xFF6BB6E0), darkBg: Color(0xFF121A1E)),
    // 3: 薄荷绿
    (name: '薄荷绿', lightColor: Color(0xFF7BB661), lightBg: Color(0xFFF5FBF2), darkColor: Color(0xFF7BB661), darkBg: Color(0xFF161A16)),
    // 4: 薰衣草
    (name: '薰衣草', lightColor: Color(0xFF9B59B6), lightBg: Color(0xFFFAF5FC), darkColor: Color(0xFF9B59B6), darkBg: Color(0xFF1A1624)),
    // 5: 珊瑚橘
    (name: '珊瑚橘', lightColor: Color(0xFFFF8C5A), lightBg: Color(0xFFFFFBF8), darkColor: Color(0xFFFF8C5A), darkBg: Color(0xFF1A1612)),
    // 6: 星空灰
    (name: '星空灰', lightColor: Color(0xFF607D8B), lightBg: Color(0xFFF5F7FA), darkColor: Color(0xFF78909C), darkBg: Color(0xFF121212)),
    // 7: 梦幻紫
    (name: '梦幻紫', lightColor: Color(0xFFB388FF), lightBg: Color(0xFFF8F5FF), darkColor: Color(0xFFB388FF), darkBg: Color(0xFF1A1624)),
    // 8: 樱花粉（新增）— 春日柔美
    (name: '樱花粉', lightColor: Color(0xFFFFB7C5), lightBg: Color(0xFFFFF0F3), darkColor: Color(0xFFFFB7C5), darkBg: Color(0xFF1A1416)),
    // 9: 森林绿（新增）— 自然清新
    (name: '森林绿', lightColor: Color(0xFF5D9B6A), lightBg: Color(0xFFF2F8F3), darkColor: Color(0xFF6DBE7C), darkBg: Color(0xFF141A16)),
  ];

  int _accentIndex = 0;
  double _fontScale = 1.0; // 0.9=小, 1.0=标准, 1.15=大
  bool _showWeekend = true;
  bool _showClassTime = false;
  bool _isDarkMode = false;

  int get accentIndex => _accentIndex;
  double get fontScale => _fontScale;
  bool get showWeekend => _showWeekend;
  bool get showClassTime => _showClassTime;
  bool get isDarkMode => _isDarkMode;

  Color get accentColor => _isDarkMode ? themes[_accentIndex].darkColor : themes[_accentIndex].lightColor;
  Color get bgColor => _isDarkMode ? themes[_accentIndex].darkBg : themes[_accentIndex].lightBg;
  
  /// 获取当前主题的文本颜色（根据深色/浅色模式自适应）
  Color get textPrimary => _isDarkMode ? const Color(0xFFF5F5F5) : DesignTokens.textPrimary;
  Color get textSecondary => _isDarkMode ? const Color(0xFFB0B0B0) : DesignTokens.textSecondary;
  Color get textAux1 => _isDarkMode ? const Color(0xFF808080) : DesignTokens.textAux1;
  Color get cardColor => _isDarkMode ? const Color(0xFF242424) : DesignTokens.card;
  Color get borderColor => _isDarkMode ? const Color(0xFF333333) : DesignTokens.border;

  ThemeProvider() {
    _initBox();
  }

  void _initBox() {
    try {
      _box = Hive.box('settings');
    } catch (e) {
      debugPrint('⚠️ ThemeProvider: settings box not open yet: $e');
      // 延迟重试
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _box = Hive.box('settings');
          _loadFromBox();
          notifyListeners();
        } catch (_) {}
      });
      return;
    }
    _loadFromBox();
    notifyListeners(); // 确保 Consumer 初始加载时使用持久化值
  }

  void _loadFromBox() {
    // Hive动态Box中数值可能以int返回（如1.0→1），必须用num安全转换
    final accentVal = _box.get(_keyAccentIndex, defaultValue: 0);
    final fontVal = _box.get(_keyFontScale, defaultValue: 1.0);
    final weekendVal = _box.get(_keyShowWeekend, defaultValue: true);
    final classTimeVal = _box.get(_keyShowClassTime, defaultValue: false);
    final darkModeVal = _box.get(_keyDarkMode, defaultValue: false);

    _accentIndex = (accentVal as num).toInt();
    _fontScale = (fontVal as num).toDouble();
    _showWeekend = weekendVal as bool;
    _showClassTime = classTimeVal as bool;
    _isDarkMode = darkModeVal as bool;

    debugPrint('🎨 ThemeProvider loaded: accentIndex=$accentIndex, fontScale=$fontScale, showWeekend=$showWeekend, showClassTime=$showClassTime, isDarkMode=$_isDarkMode');
  }

  void _save() {
    _box.put(_keyAccentIndex, _accentIndex);
    _box.put(_keyFontScale, _fontScale);
    _box.put(_keyShowWeekend, _showWeekend);
    _box.put(_keyShowClassTime, _showClassTime);
    _box.put(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  void setAccentIndex(int index) {
    _accentIndex = index;
    _save();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    _save();
  }

  void toggleShowWeekend() {
    _showWeekend = !_showWeekend;
    _save();
  }

  void toggleShowClassTime() {
    _showClassTime = !_showClassTime;
    _save();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _save();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _save();
  }

  /// 根据当前设置生成 ThemeData
  ThemeData get currentTheme {
    final accent = accentColor;
    final bg = bgColor;
    final brightness = _isDarkMode ? Brightness.dark : Brightness.light;
    
    return ThemeData(
      fontFamily: 'SarasaGothicSC',
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: accent,
        onPrimary: _isDarkMode ? const Color(0xFF1A1A1A) : DesignTokens.textPrimary,
        surface: bg,
        onSurface: textPrimary,
        secondary: _isDarkMode ? const Color(0xFF333333) : DesignTokens.pillBg,
        onSecondary: textSecondary,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'SarasaGothicSC',
          fontSize: DesignTokens.titleSize * _fontScale,
          fontWeight: DesignTokens.titleWeight,
          color: textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : DesignTokens.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadiusLarge),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
    );
  }
}
