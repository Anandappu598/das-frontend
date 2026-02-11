import 'package:dio/dio.dart';
import 'package:project_pm/src/core/networking/api_client.dart';
import 'package:project_pm/src/features/auth/models/auth_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(dioProvider));
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Login user
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/login/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to login');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Invalid email or password');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Request signup (sends OTP to admin)
  Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final response = await _dio.post(
        '/signup/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return SignupResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to signup');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Signup failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Verify signup with OTP
  Future<VerifySignupResponse> verifySignup(VerifySignupRequest request) async {
    try {
      final response = await _dio.post(
        '/verify-signup/',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VerifySignupResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to verify signup');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Invalid or expired OTP');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Request password reset (sends OTP to user email)
  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/forgot-password/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return ForgotPasswordResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to request password reset');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? errorData['detail'] ?? 'User not found');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Reset password with OTP
  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/reset-password/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return ResetPasswordResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to reset password');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Invalid OTP');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
