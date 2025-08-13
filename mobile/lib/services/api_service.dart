import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;
  
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://openai-rewrite.onrender.com/heywish/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        handler.next(error);
      },
    ));
  }
  
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  void clearAuthToken() {
    _authToken = null;
  }
  
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> patch(String path, dynamic data) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        
        switch (statusCode) {
          case 400:
            return 'Bad request: $message';
          case 401:
            return 'Unauthorized. Please sign in again.';
          case 403:
            return 'Forbidden. You don\'t have permission to access this resource.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return message;
        }
      
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') ?? false) {
          return 'No internet connection.';
        }
        return 'An unexpected error occurred.';
      
      default:
        return 'An error occurred. Please try again.';
    }
  }
}