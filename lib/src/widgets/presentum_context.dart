import 'package:flutter/material.dart';

/// {@template presentum_context}
/// Inherited widget that provides the [Presentum] instance to the widget tree.
/// {@endtemplate}
class InheritedResolvedPresentum<TResolved> extends InheritedWidget {
  /// {@macro presentum_context}
  const InheritedResolvedPresentum({
    required this.item,
    required super.child,
    super.key,
  });

  /// The item that is being presented.
  final TResolved item;

  /// Get the [InheritedResolvedPresentum] instance from the context.
  static InheritedResolvedPresentum<TResolved> of<TResolved>(
    BuildContext context,
  ) => maybeOf(context) ?? _notFoundInheritedWidgetOfExactType();

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a InheritedPresentationItem of the exact type',
    'out_of_scope',
  );

  /// Get the [InheritedResolvedPresentum] instance from the context, if it
  /// exists.
  static InheritedResolvedPresentum<TResolved>? maybeOf<TResolved>(
    BuildContext context, {
    bool listen = true,
  }) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedResolvedPresentum<TResolved>
            >()
      : context
            .getInheritedWidgetOfExactType<
              InheritedResolvedPresentum<TResolved>
            >();

  @override
  bool updateShouldNotify(InheritedResolvedPresentum<TResolved> oldWidget) =>
      oldWidget.item != item;
}
