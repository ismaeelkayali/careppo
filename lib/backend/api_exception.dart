// lib/backend/api_exception.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      "ApiException(status: $statusCode, message: $message, details: $details)";
}
