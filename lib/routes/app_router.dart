import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/backpack_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/semester_screen.dart';
import '../screens/students_screen.dart';
import '../screens/course_input_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/subject_selector_screen.dart';
import '../screens/reminder_screen.dart';
import '../screens/homework_screen.dart';
import '../screens/copy_schedule_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/holiday_calendar_screen.dart';
import '../screens/export_screen.dart';
import '../screens/time_slot_settings_screen.dart';
import '../screens/time_slot_edit_screen.dart';
import '../screens/subject_color_settings_screen.dart';
import '../widgets/pill_tab_bar.dart';

/// 应用路由配置
/// 使用 GoRouter 管理 页面导航

// 临时占位页面（后续由各屏替换）
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

class AppRouter {
  /// GoRouter 实例
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final onboardingProvider = context.read<OnboardingProvider>();
      final isComplete = onboardingProvider.isOnboardingComplete;
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // 如果引导未完成且不在引导页，跳转引导页
      if (!isComplete && !isOnOnboarding) {
        return '/onboarding';
      }
      // 如果引导已完成且在引导页，跳转主页
      if (isComplete && isOnOnboarding) {
        return '/tabs/schedule';
      }
      return null;
    },
    routes: [
      // 引导流程
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 主页面 - 使用 ShellRoute 包裹底部导航
      ShellRoute(
        builder: (context, state, child) {
          // 根据当前路由确定 Tab 索引
          final location = state.matchedLocation;
          int tabIndex = 0;
          if (location.startsWith('/tabs/backpack')) tabIndex = 1;
          else if (location.startsWith('/tabs/students')) tabIndex = 2;
          else if (location.startsWith('/tabs/settings')) tabIndex = 3;

          return Scaffold(
            body: child,
            bottomNavigationBar: PillTabBar(
              currentIndex: tabIndex,
              onTabChanged: (_) {},
            ),
          );
        },
        routes: [
          // 课表 Tab
          GoRoute(
            path: '/tabs/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          // 书包 Tab
          GoRoute(
            path: '/tabs/backpack',
            builder: (context, state) => const BackpackScreen(),
          ),
          // 学生 Tab
          GoRoute(
            path: '/tabs/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          // 设置 Tab
          GoRoute(
            path: '/tabs/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              // 学期管理子页面
              GoRoute(
                path: 'semester',
                builder: (context, state) => const SemesterScreen(),
              ),
            ],
          ),
        ],
      ),

      // 添加/编辑课程页面
      GoRoute(
        path: '/students/:id/course/add',
        builder: (context, state) {
          final studentId = state.pathParameters['id']!;
          final courseId = state.uri.queryParameters['courseId'];
          // 空白格子点击时传入的初始星期和节次
          final initialDay = state.uri.queryParameters['day'];
          final initialPeriod = state.uri.queryParameters['period'];
          return CourseInputScreen(
            studentId: studentId,
            courseId: courseId,
            initialDay: initialDay != null ? int.tryParse(initialDay) : null,
            initialPeriod: initialPeriod != null ? int.tryParse(initialPeriod) : null,
          );
        },
      ),

      // 提醒管理页面（从书包页面入口进入）
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const ReminderScreen(),
      ),

      // 家庭作业页面
      GoRoute(
        path: '/homework',
        builder: (context, state) => const HomeworkScreen(),
      ),

      // 一键复制课表
      GoRoute(
        path: '/schedule/copy',
        builder: (context, state) => const CopyScheduleScreen(),
      ),

      // 主题设置
      GoRoute(
        path: '/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),

      // 假期日历
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const HolidayCalendarScreen(),
      ),

      // 导出/分享
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),

      // 科目颜色设置
      GoRoute(
        path: '/subject-colors',
        builder: (context, state) => const SubjectColorSettingsScreen(),
      ),

      // 时间点配置
      GoRoute(
        path: '/time-slots',
        builder: (context, state) => const TimeSlotSettingsScreen(),
      ),

      // 时间点编辑
      GoRoute(
        path: '/time-slots/edit',
        builder: (context, state) {
          final slotId = state.uri.queryParameters['slotId'];
          return TimeSlotEditScreen(slotId: slotId);
        },
      ),

      // 科目选择（底部弹窗路由）
      GoRoute(
        path: '/subject/select',
        builder: (context, state) => const SubjectSelectorScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SubjectSelectorScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            );
          },
        ),
      ),

      // 某日课表详情
      GoRoute(
        path: '/schedule/day',
        builder: (context, state) {
          final dayOfWeek = state.uri.queryParameters['day'] ?? '1';
          return _PlaceholderScreen(title: '第$dayOfWeek天课表');
        },
      ),
    ],
  );
}
