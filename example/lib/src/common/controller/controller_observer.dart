import 'dart:developer' as dev;

import 'package:example/src/common/controller/controller.dart';

class ControllerObserver implements IControllerObserver {
  @override
  void onCreate(IController controller) {
    dev.log('Controller | ${controller.runtimeType} | Created');
  }

  @override
  void onDispose(IController controller) {
    dev.log('Controller | ${controller.runtimeType} | Disposed');
  }

  @override
  void onStateChanged(
    IController controller,
    Object prevState,
    Object nextState,
  ) {
    dev.log(
      'Controller | ${controller.runtimeType} | $prevState -> $nextState',
    );
  }

  @override
  void onError(IController controller, Object error, StackTrace stackTrace) {
    dev.log(
      'Controller | ${controller.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
