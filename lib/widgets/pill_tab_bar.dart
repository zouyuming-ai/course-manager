import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';

/// 底部导航 PillTabBar 组件
/// 设计规格：95h × 全宽, 圆角36, fill=#F5EED4
/// Active Tab: fill=#FFC857, 文字600weight, 图标实心
/// Inactive: 透明底, 文字#888888, 图标线条

class PillTabBar extends StatelessWidget {
  /// 当前选中的 Tab 索引
  final int currentIndex;

  /// Tab 切换回调
  final ValueChanged<int> onTabChanged;

  const PillTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  /// Tab 定义列表
  static const List<_TabItem> _tabs = [
    _TabItem(label: '课表', icon: Icons.calendar_view_week, activeIcon: Icons.calendar_view_week),
    _TabItem(label: '书包', icon: Icons.backpack_outlined, activeIcon: Icons.backpack),
    _TabItem(label: '学生', icon: Icons.people_outline, activeIcon: Icons.people),
    _TabItem(label: '设置', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  /// 对应的路由路径
  static const List<String> _routes = [
    '/tabs/schedule',
    '/tabs/backpack',
    '/tabs/students',
    '/tabs/settings',
  ];

  @override
  Widget build(BuildContext context) {
    // 底部安全区
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: DesignTokens.tabBarHeight + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: DesignTokens.pillBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.pillRadius),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isActive = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                onTabChanged(index);
                context.go(_routes[index]);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 62,
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? DesignTokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.pillRadiusSmall),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      size: 22,
                      color: isActive ? DesignTokens.textPrimary : DesignTokens.textAux1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: DesignTokens.tagSizeLarge,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? DesignTokens.textPrimary : DesignTokens.textAux1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tab 数据模型
class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
