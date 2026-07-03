import 'package:flutter/material.dart';
import 'package:course_manager/widgets/subject_selector.dart';

/// 科目选择器页面路由包装
/// GoRouter 路由 /subject/select 对应的页面
/// 内部实际调用 SubjectSelector Bottom Sheet 并返回结果

class SubjectSelectorScreen extends StatefulWidget {
  const SubjectSelectorScreen({super.key});

  @override
  State<SubjectSelectorScreen> createState() => _SubjectSelectorScreenState();
}

class _SubjectSelectorScreenState extends State<SubjectSelectorScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载后立即弹出 Bottom Sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubjectSelector();
    });
  }

  Future<void> _showSubjectSelector() async {
    final result = await SubjectSelector.showSubjectSelector(context);
    // 将选择结果通过 Navigator.pop 传递回路由调用方
    if (result != null && mounted) {
      Navigator.pop(context, result);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 过渡页面：在 Bottom Sheet 弹出前短暂显示透明背景
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
