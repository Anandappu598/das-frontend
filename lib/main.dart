import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pm/src/app.dart';
import 'package:project_pm/src/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file for API keys
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('Loaded .env file with API key');
  } catch (e) {
    // .env file not found - will use --dart-define instead
    debugPrint('No .env file found, using --dart-define for API keys');
  }

  // Load SharedPreferences with fallback to prevent startup crash
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize SharedPreferences: $e');
    // We will handle the null case in the ProviderContainer override
  }

  final container = ProviderContainer(
    overrides: [
      if (prefs != null)
        sharedPreferencesProvider.overrideWithValue(prefs)
      else
        // If prefs is null, the app will use default values in ThemeNotifier
        // but we need to ensure the provider itself doesn't throw UnimplementedError
        sharedPreferencesProvider
            .overrideWith((ref) => throw Exception('Prefs not available')),
    ],
  );

  // Skip database seeding on web - Drift WASM not fully configured
  // Database seeding is now handled in StartupPage

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ProjectPmApp(),
    ),
  );
}
