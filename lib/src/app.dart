import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/theme/theme_provider.dart';
import 'package:project_pm/src/routes/app_router.dart';

class ProjectPmApp extends ConsumerStatefulWidget {
  const ProjectPmApp({super.key});

  @override
  ConsumerState<ProjectPmApp> createState() => _ProjectPmAppState();
}

class _ProjectPmAppState extends ConsumerState<ProjectPmApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(resolvedThemeModeProvider);

    return MaterialApp.router(
      title: 'Power Project Manager',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _appRouter.config(),
    );
  }
}
