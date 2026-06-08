import 'dart:async';
import 'dart:developer' as dev;

/* import 'package:database/database.dart'; */
import 'package:control/control.dart';
import 'package:example/src/app/initialization/data/initialize_dependencies.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared/shared.dart';

class ControllerObserver implements IControllerObserver {
  const ControllerObserver();

  @override
  void onCreate(Controller controller) {
    dev.log(
      'Controller | ${controller.runtimeType} | Created',
      name: 'ControllerObserver',
    );
  }

  @override
  void onDispose(Controller controller) {
    dev.log(
      'Controller | ${controller.runtimeType} | Disposed',
      name: 'ControllerObserver',
    );
  }

  @override
  void onStateChanged<S extends Object>(
    StateController<S> controller,
    S prevState,
    S nextState,
  ) {
    final context = Controller.context;
    if (context == null) {
      // State change occurred outside of the handler
      dev.log(
        'StateController | '
        '${controller.name} | '
        '$prevState -> $nextState',
        name: 'ControllerObserver',
      );
    } else {
      // State change occurred inside the handler
      dev.log(
        'StateController | '
        '${controller.name}.${context.name} | Meta: ${context.meta} | '
        '$prevState -> $nextState',
        name: 'ControllerObserver',
      );
    }
  }

  @override
  void onHandler(HandlerContext context) {
    final stopwatch = Stopwatch()..start();
    dev.log(
      'Controller | '
      '${context.controller.name}.${context.name} | Meta: ${context.meta}',
      name: 'ControllerObserver',
    );
    context.done.whenComplete(() {
      stopwatch.stop();
      dev.log(
        'Controller | '
        '${context.controller.name}.${context.name} | '
        'duration: ${stopwatch.elapsed} | Meta: ${context.meta}',
        name: 'ControllerObserver',
      );
    });
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    final context = Controller.context;
    if (context == null) {
      // Error occurred outside of the handler
      dev.log(
        'Controller | '
        '${controller.name}',
        error: error,
        stackTrace: stackTrace,
        name: 'ControllerObserver',
      );
    } else {
      // Error occurred inside the handler
      dev.log(
        'Controller | '
        '${controller.name}.${context.name} | '
        'Meta: ${context.meta} | ',
        error: error,
        stackTrace: stackTrace,
        name: 'ControllerObserver',
      );
    }
  }
}

/// Ephemerally initializes the app and prepares it for use.
Future<Dependencies>? _$initializeApp;

/// Initializes the app and prepares it for use.
Future<Dependencies> $initializeApp({
  void Function(int progress, String message)? onProgress,
  FutureOr<void> Function(Dependencies dependencies)? onSuccess,
  void Function(Object error, StackTrace stackTrace)? onError,
}) => _$initializeApp ??= Future<Dependencies>(() async {
  late final WidgetsBinding binding;
  final stopwatch = Stopwatch()..start();

  Controller.observer = const ControllerObserver();
  try {
    binding = WidgetsFlutterBinding.ensureInitialized()..deferFirstFrame();
    /* await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]); */
    await _catchExceptions();
    final dependencies = await $initializeDependencies(
      onProgress: onProgress,
    ).timeout(const Duration(minutes: 7));
    await onSuccess?.call(dependencies);
    return dependencies;
  } on Object catch (error, stackTrace) {
    onError?.call(error, stackTrace);
    ErrorUtil.logError(
      error,
      stackTrace,
      hint: 'Failed to initialize app',
    ).ignore();
    rethrow;
  } finally {
    stopwatch.stop();
    binding.addPostFrameCallback((_) {
      // Closes splash screen, and show the app layout.
      binding.allowFirstFrame();
      //final context = binding.renderViewElement;
    });
    _$initializeApp = null;
  }
});

/// Resets the app's state to its initial state.
@visibleForTesting
Future<void> $resetApp(Dependencies dependencies) async {}

/// Disposes the app and releases all resources.
@visibleForTesting
Future<void> $disposeApp(Dependencies dependencies) async {}

Future<void> _catchExceptions() async {
  try {
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      ErrorUtil.logError(
        error,
        stackTrace,
        hint: 'ROOT ERROR\r\n${Error.safeToString(error)}',
      ).ignore();
      return true;
    };

    // final sourceFlutterError = FlutterError.onError;
    FlutterError.onError = (final details) {
      ErrorUtil.logError(
        details.exception,
        details.stack ?? StackTrace.current,
        hint: 'FLUTTER ERROR\r\n$details',
      ).ignore();
      // FlutterError.presentError(details);
      // sourceFlutterError?.call(details);
    };
  } on Object catch (error, stackTrace) {
    ErrorUtil.logError(error, stackTrace).ignore();
  }
}
