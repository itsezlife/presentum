import 'package:example/src/maintenance/presentum/provider.dart';
import 'package:flutter/material.dart';

class MaintenanceProviderScope extends InheritedWidget {
  const MaintenanceProviderScope({
    required this.provider,
    required super.child,
    super.key,
  });

  final MaintenanceProvider provider;

  /// The provider from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `MaintenanceProviderScope.maybeOf(context)`
  static MaintenanceProviderScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MaintenanceProviderScope>();

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a MaintenanceProviderScope of the exact type',
    'out_of_scope',
  );

  /// The provider from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `MaintenanceProviderScope.of(context)`
  static MaintenanceProviderScope of(BuildContext context) =>
      maybeOf(context) ?? _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(MaintenanceProviderScope oldWidget) => false;
}
