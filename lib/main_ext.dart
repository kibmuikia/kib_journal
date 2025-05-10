part of 'main.dart';

void _handleError(String source, FlutterErrorDetails errorDetails) {
  try {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    } else {
      // TODO: send to logging utils like crashlytics.
      FlutterError.dumpErrorToConsole(errorDetails);
    }
  } catch (e) {
    kprint.err('main:_handleError: Caught ${e.runtimeType}; \n$e');
  }
}

Future<void> _initializeCoreServices() async {
  DebugPrintService.initialize();

  // Setup all service dependencies.
  final result = await setupServiceLocator();
  switch (result) {
    case Success<bool, Exception>():
      break;
    case Failure<bool, Exception>():
      throw result.error;
  }
  await getIt.allReady();
}
