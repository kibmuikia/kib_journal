import 'package:flutter/material.dart' show BuildContext;
import 'package:go_router/go_router.dart';
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_utils/kib_utils.dart' show Result, tryResult;

Result<bool, Exception> navigateToHome(BuildContext context) => tryResult(
  () {
    context.go('/home');
    return true;
  },
  (err) =>
      err is Exception
          ? err
          : ExceptionX(
            error: err,
            stackTrace: StackTrace.current,
            message:
                'Error, ${err.runtimeType}, encountered while navigating to home',
            errorType: err.runtimeType,
          ),
);
