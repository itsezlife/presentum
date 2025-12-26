import 'dart:async';

import 'package:example/src/app/initialization/data/initialization.dart'
    deferred as initialization;
import 'package:example/src/app/initialization/widget/inherited_dependencies.dart'
    deferred as inherited_dependencies;
import 'package:example/src/app/view/app_error.dart' deferred as app_error;
import 'package:example/src/app/view/app_view.dart' deferred as app;
import 'package:flutter/widgets.dart';
import 'package:shared/shared.dart';

void main() => runZonedGuarded<void>(
  () async {
    // Splash screen
    final initializationProgress =
        ValueNotifier<({int progress, String message})>((
          progress: 0,
          message: '',
        ));
    /* runApp(SplashScreen(progress: initializationProgress)); */
    await initialization.loadLibrary();
    await inherited_dependencies.loadLibrary();
    await app.loadLibrary();
    initialization
        .$initializeApp(
          onProgress: (progress, message) => initializationProgress.value = (
            progress: progress,
            message: message,
          ),
          onSuccess: (dependencies) => runApp(
            inherited_dependencies.InheritedDependencies(
              dependencies: dependencies,
              child: app.AppView(),
            ),
          ),
          onError: (error, stackTrace) async {
            await app_error.loadLibrary();
            runApp(app_error.AppError(error: error, stackTrace: stackTrace));
            ErrorUtil.logError(error, stackTrace).ignore();
          },
        )
        .ignore();
  },
  (error, stackTrace) async {
    ErrorUtil.logError(error, stackTrace).ignore();
  },
);
