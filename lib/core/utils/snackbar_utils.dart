import 'package:flutter/material.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_utils/kib_utils.dart';

Result<void, Exception> showSnackbarMessage(
  BuildContext context,
  String message, {
  int? durationSeconds,
  Color? backgroundColor,
  SnackBarAction? action,
  SnackBarBehavior? behavior,
  VoidCallback? onVisible,
}) {
  return tryResult(
    () {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.black,
            ),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
          duration:
              durationSeconds != null
                  ? Duration(seconds: durationSeconds)
                  : Duration(seconds: 3),
          backgroundColor: backgroundColor,
          action: action,
          behavior: behavior,
          onVisible: onVisible,
        ),
      );
    },
    (err) => ExceptionX(
      error: err,
      stackTrace: StackTrace.current,
      message: 'Error, ${err.runtimeType}, encountered while showing snackbar',
      errorType: err.runtimeType,
    ),
  );
}

extension SnackbarExtension on BuildContext {
  Result<void, Exception> showMessage(
    String message, {
    int? durationSeconds,
    Color? backgroundColor,
    SnackBarAction? action,
    SnackBarBehavior? behavior,
    VoidCallback? onVisible,
  }) => showSnackbarMessage(
    this,
    message,
    durationSeconds: durationSeconds,
    backgroundColor: backgroundColor,
    action: action,
    behavior: behavior,
    onVisible: onVisible,
  );
}
