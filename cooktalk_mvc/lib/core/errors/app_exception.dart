abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class ApiException extends AppException {
  ApiException(super.message, {super.code, super.originalError});
}

class GeminiException extends AppException {
  GeminiException(super.message, {super.code, super.originalError});
}

class YouTubeException extends AppException {
  YouTubeException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}
