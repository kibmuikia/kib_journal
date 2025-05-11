
import 'package:equatable/equatable.dart';

class ExceptionX extends Equatable implements Exception {
  final String message;
  final Type errorType;
  final Object error;
  final StackTrace stackTrace;

  ExceptionX({
    required this.message,
    required this.errorType,
    required this.error,
    required this.stackTrace,
  }) : assert(message.isNotEmpty, 'Exception message must not be empty');

  @override
  List<Object?> get props => [message, errorType, error];

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
