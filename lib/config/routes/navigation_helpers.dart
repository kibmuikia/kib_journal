import 'package:flutter/material.dart' show BuildContext;
import 'package:go_router/go_router.dart';
import 'package:kib_journal/config/routes/router_config.dart' show AppRoutes;
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_utils/kib_utils.dart' show Result, tryResult;

Result<void, Exception> navigateToHome(
  BuildContext context, {
  Object? extra,
}) => tryResult(
  () {
    context.go(AppRoutes.home.path, extra: extra);
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

Result<void, Exception> navigateToSignIn(
  BuildContext context, {
  Object? extra,
}) => tryResult(
  () {
    context.go(AppRoutes.signIn.path, extra: extra);
  },
  (err) =>
      err is Exception
          ? err
          : ExceptionX(
            error: err,
            stackTrace: StackTrace.current,
            message:
                'Error, ${err.runtimeType}, encountered while navigating to sign in',
            errorType: err.runtimeType,
          ),
);

Result<void, Exception> navigateToSignUp(
  BuildContext context, {
  Object? extra,
}) => tryResult(
  () {
    context.go(AppRoutes.signUp.path, extra: extra);
  },
  (err) =>
      err is Exception
          ? err
          : ExceptionX(
            error: err,
            stackTrace: StackTrace.current,
            message:
                'Error, ${err.runtimeType}, encountered while navigating to sign up',
            errorType: err.runtimeType,
          ),
);
