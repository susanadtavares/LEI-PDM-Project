// lib/API/exceptions.dart

class ApiException implements Exception {
  final String? message;
  ApiException([this.message]);
}
