class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class TimeoutException extends ApiException {
  TimeoutException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message) : super(statusCode: 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

class ConflictException extends ApiException {
  ConflictException(super.message) : super(statusCode: 409);
}

class ValidationException extends ApiException {
  final dynamic errors;

  ValidationException(super.message, {this.errors}) : super(statusCode: 422);

  Map<String, List<String>> get fieldErrors {
    if (errors == null) return {};
    if (errors is Map<String, dynamic>) {
      return errors.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.cast<String>());
        }
        return MapEntry(key, [value.toString()]);
      });
    }
    return {};
  }
}

class TooManyRequestsException extends ApiException {
  TooManyRequestsException(super.message) : super(statusCode: 429);
}

class ServerException extends ApiException {
  ServerException(super.message) : super(statusCode: 500);
}
