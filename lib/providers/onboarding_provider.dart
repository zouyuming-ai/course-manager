import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// 引导流程管理 Provider
class OnboardingProvider extends ChangeNotifier {
  final Box _settingsBox = Hive.box('settings');

  int _currentStep = 0;
  bool _isOnboardingComplete = false;

  int get currentStep => _currentStep;
  bool get isOnboardingComplete => _isOnboardingComplete;

  /// 引导流程共4步（0-3）
  static const int totalSteps = 4;

  /// 初始化：从 settings 读取引导状态
  OnboardingProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _isOnboardingComplete = _settingsBox.get('onboardingComplete', defaultValue: false);
    notifyListeners();
  }

  /// 下一步
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  /// 完成引导流程
  void completeOnboarding() {
    _isOnboardingComplete = true;
    _settingsBox.put('onboardingComplete', true);
    notifyListeners();
  }

  /// 重置引导流程（用于设置中重新触发）
  void resetOnboarding() {
    _currentStep = 0;
    _isOnboardingComplete = false;
    _settingsBox.put('onboardingComplete', false);
    notifyListeners();
  }
}
