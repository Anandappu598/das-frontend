import 'package:project_pm/src/features/auth/auth_repository.dart';
import 'package:project_pm/src/features/auth/models/auth_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state_providers.g.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? userEmail;
  final UserRole? userRole;
  final String? themePreference;

  const AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.userEmail,
    this.userRole,
    this.themePreference,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? userEmail,
    UserRole? userRole,
    String? themePreference,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

/// Auth state notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    // Load saved auth state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    final userEmail = prefs.getString('user_email');
    final roleString = prefs.getString('user_role');
    final themePreference = prefs.getString('theme_preference');

    if (accessToken != null && userEmail != null) {
      return AuthState(
        isAuthenticated: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        userEmail: userEmail,
        userRole: roleString != null ? UserRole.fromString(roleString) : null,
        themePreference: themePreference,
      );
    }

    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(
        LoginRequest(email: email, password: password),
      );

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.access);
      await prefs.setString('refresh_token', response.refresh);
      await prefs.setString('user_email', response.email);
      await prefs.setString('user_role', response.role);
      await prefs.setString('theme_preference', response.themePreference);

      return AuthState(
        isAuthenticated: true,
        accessToken: response.access,
        refreshToken: response.refresh,
        userEmail: response.email,
        userRole: UserRole.fromString(response.role),
        themePreference: response.themePreference,
      );
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('theme_preference');

    state = const AsyncValue.data(AuthState());
  }
}

/// Signup notifier
@riverpod
class SignupNotifier extends _$SignupNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  Future<SignupResponse> requestSignup({
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    
    final response = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.signup(
        SignupRequest(email: email, password: password, role: role),
      );
    });

    if (response.hasError) {
      state = AsyncValue.error(response.error!, response.stackTrace!);
      throw response.error!;
    }

    state = const AsyncValue.data(null);
    return response.value!;
  }

  Future<VerifySignupResponse> verifySignup({
    required String email,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    
    final response = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.verifySignup(
        VerifySignupRequest(email: email, otp: otp),
      );
    });

    if (response.hasError) {
      state = AsyncValue.error(response.error!, response.stackTrace!);
      throw response.error!;
    }

    state = const AsyncValue.data(null);
    return response.value!;
  }
}

/// Password reset notifier
@riverpod
class PasswordResetNotifier extends _$PasswordResetNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  Future<ForgotPasswordResponse> requestPasswordReset({
    required String email,
  }) async {
    state = const AsyncValue.loading();
    
    final response = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.forgotPassword(
        ForgotPasswordRequest(email: email),
      );
    });

    if (response.hasError) {
      state = AsyncValue.error(response.error!, response.stackTrace!);
      throw response.error!;
    }

    state = const AsyncValue.data(null);
    return response.value!;
  }

  Future<ResetPasswordResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    
    final response = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.resetPassword(
        ResetPasswordRequest(email: email, otp: otp, newPassword: newPassword),
      );
    });

    if (response.hasError) {
      state = AsyncValue.error(response.error!, response.stackTrace!);
      throw response.error!;
    }

    state = const AsyncValue.data(null);
    return response.value!;
  }
}
