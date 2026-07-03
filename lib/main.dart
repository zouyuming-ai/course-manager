import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'providers/student_provider.dart';
import 'providers/semester_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/backpack_provider.dart';
import 'providers/onboarding_provider.dart';
import 'models/student.dart';
import 'models/semester.dart';
import 'models/course_schedule.dart';
import 'models/subject_color.dart';
import 'models/time_slot.dart';
import 'models/reminder.dart';
import 'models/homework.dart';
import 'models/backpack_item.dart';
import 'providers/homework_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/time_slot_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误捕获 — 防止白屏崩溃
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 [FlutterError] ${details.exception}');
  };

  await Hive.initFlutter();

  // 注册所有 Hive TypeAdapter
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(SemesterAdapter());
  Hive.registerAdapter(CourseScheduleAdapter());
  Hive.registerAdapter(SubjectColorAdapter());
  Hive.registerAdapter(TimeSlotAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(HomeworkAdapter()); // typeId: 8
  Hive.registerAdapter(BackpackItemAdapter());

  // ===== 安全打开所有 Boxes =====
  try { await _safeOpenTyped<Student>('students'); } catch (_) {}
  try { await _safeOpenTyped<Semester>('semesters'); } catch (_) {}
  try { await _safeOpenTyped<CourseSchedule>('schedules'); } catch (_) {}
  try { await _safeOpenTyped<SubjectColor>('subjectColors'); } catch (_) {}
  try { await _safeOpenTyped<TimeSlot>('timeSlots'); } catch (_) {}
  try { await _safeOpenTyped<Reminder>('reminders'); } catch (_) {}
  try { await _safeOpenTyped<Homework>('homework'); } catch (_) {}
  try { await _safeOpenTyped<BackpackItem>('backpackItems'); } catch (_) {}
  try { await _safeOpenDynamic('settings'); } catch (_) {}

  // ===== 初始化推送通知 =====
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(const CourseManagerApp());
}

/// 安全打开**类型化** Box
/// 失败时自动关闭后重新创建空 Box
Future<void> _safeOpenTyped<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
    debugPrint('✅ TypedBox [$boxName] OK');
  } catch (e) {
    debugPrint('⚠️ TypedBox [$boxName] 失败: $e');
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
    await Hive.openBox<T>(boxName);
    debugPrint('🔄 TypedBox [$boxName] 重建成功（空）');
  }
}

/// 安全打开动态 Box（settings）
Future<void> _safeOpenDynamic(String boxName) async {
  try {
    await Hive.openBox(boxName);
    debugPrint('✅ DynamicBox [$boxName] OK');
  } catch (e) {
    debugPrint('⚠️ DynamicBox [$boxName] 失败: $e');
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
    await Hive.openBox(boxName);
    debugPrint('🔄 DynamicBox [$boxName] 重建成功');
  }
}

class CourseManagerApp extends StatelessWidget {
  const CourseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => BackpackProvider()),
        ChangeNotifierProvider(create: (_) => HomeworkProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimeSlotProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: '课程小管家',
            theme: themeProvider.currentTheme,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            // 中文本地化：日期/时间选择器显示中文
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            locale: const Locale('zh', 'CN'),
          );
        },
      ),
    );
  }
}
