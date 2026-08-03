import 'dart:async';

class ApiResponse<T> {
  const ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  final int statusCode;
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  factory ApiResponse.ok(T data, {String? message}) {
    return ApiResponse(
      statusCode: 200,
      success: true,
      data: data,
      message: message ?? 'Thành công',
    );
  }

  factory ApiResponse.created(T data, {String? message}) {
    return ApiResponse(
      statusCode: 201,
      success: true,
      data: data,
      message: message ?? 'Tạo mới thành công',
    );
  }

  factory ApiResponse.error(int statusCode, String error) {
    return ApiResponse(
      statusCode: statusCode,
      success: false,
      error: error,
    );
  }
}

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  // Giả lập độ trễ mạng thực tế (Network Latency)
  Future<void> _simulateLatency([int ms = 400]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  // Wrapper gọi REST API an toàn với xử lý lỗi
  Future<ApiResponse<T>> request<T>(Future<T> Function() apiCall) async {
    await _simulateLatency();
    try {
      final result = await apiCall();
      return ApiResponse.ok(result);
    } catch (e) {
      return ApiResponse.error(500, 'Lỗi Server: ${e.toString()}');
    }
  }
}
