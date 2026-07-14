/// App 版本号常量
/// 每次构建新 APK 时，同步更新此文件和 pubspec.yaml 的 version 字段
/// pubspec.yaml 格式: major.minor.patch+buildNumber
/// 此文件格式: 'v{major.minor.patch} (build {buildNumber})'
class AppVersion {
  /// 版本号字符串，用于设置页和关于对话框
  /// 与 pubspec.yaml version 字段保持一致
  static const String version = 'v1.0.26';
  static const int buildNumber = 26;

  /// 完整版本字符串
  static const String fullVersion = 'v1.0.26 (26)';
}
