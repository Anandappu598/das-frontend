import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pm/src/core/database/seed_service.dart';
import 'package:project_pm/src/routes/app_router.dart';

// ignore: unused_import
import 'dart:async';

@RoutePage()
class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({super.key});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  bool _showSkipButton = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _initialize();

    // Show manual skip button if initialization takes longer than 3 seconds
    _skipTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSkipButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint('StartupPage: Beginning Initialization...');

    try {
      // 1. Seed Database with Timeout
      final seedService = ref.read(seedServiceProvider);

      await Future.any([
        seedService.seedData(),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Database seeding timed out');
        }),
      ]);

      debugPrint('StartupPage: Database seeded successfully');

      // 2. Wait for a short duration to ensure providers are ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      debugPrint('StartupPage: Initialization Error: $e');
      // Even on error, we should let the user in
      if (mounted) {
        // Short delay to let them see the error log if debugging
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToDashboard();
      }
    }
  }

  void _navigateToDashboard() {
    _skipTimer?.cancel();
    debugPrint('StartupPage: Navigating to Dashboard');
    context.router.replace(const ShellRoute(children: [DashboardRoute()]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Initializing Power PM...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_showSkipButton) ...[
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _navigateToDashboard,
                  icon: const Icon(Icons.skip_next),
                  label:
                      const Text('Is it taking too long? Skip Initialization'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
