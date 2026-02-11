import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final dio = Dio();
  // Configure dio (base options, interceptors)
  // dio.options.baseUrl = 'https://api.example.com';
  return dio;
}
