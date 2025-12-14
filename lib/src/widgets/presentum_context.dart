// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_resolved_variant_context}
/// Inherited widget that provides the [ResolvedPresentumVariant] instance
/// to the widget tree.
/// {@endtemplate}
class InheritedPresentumResolvedVariant<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends InheritedWidget {
  /// {@macro presentum_resolved_variant_context}
  const InheritedPresentumResolvedVariant({
    required this.item,
    required super.child,
    super.key,
  });

  /// The item that is being presented.
  final TResolved item;

  /// Method that allows widgets to access a [ResolvedPresentumVariant] instance
  /// as long as their `BuildContext` contains an
  /// [InheritedPresentumResolvedVariant] instance.
  ///
  /// If we want to access an instance of a resolved presentum variant which was
  /// provided higher up in the widget tree we can do so via:
  ///
  /// ```dart
  /// InheritedPresentumResolvedVariant.of<MyResolvedVariant, MySurface, MyVisualVariant>(context);
  /// ```
  static InheritedPresentumResolvedVariant<TResolved, S, V> of<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = false}) =>
      maybeOf<TResolved, S, V>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType<TResolved, S, V>();

  static Never _notFoundInheritedWidgetOfExactType<TResolved, S, V>() =>
      throw FlutterError('''
      InheritedPresentumResolvedVariant.of<$TResolved, $S, $V>() called with a context that does 
      not contain a resolved presentum variant.
      No ancestor could be found starting from the context that was passed to 
      InheritedPresentumResolvedVariant.of<$TResolved, $S, $V>().

      This can happen if the context you used comes from a widget above the InheritedPresentumResolvedVariant<$TResolved, $S, $V>().

      To fix this:
      1. Make sure your widget is wrapped with an InheritedPresentumResolvedVariant<$TResolved, $S, $V>()
      2. Ensure the generic types match exactly between the provider and consumer
      3. Check that the context comes from a widget below the InheritedPresentumResolvedVariant<$TResolved, $S, $V>() in the widget tree
    ''');

  /// Method that allows widgets to access a [ResolvedPresentumVariant] instance
  /// as long as their `BuildContext` contains an
  /// [InheritedPresentumResolvedVariant] instance.
  ///
  /// If we want to access an instance of a resolved presentum variant which was
  /// provided higher up in the widget tree we can do so via:
  ///
  /// ```dart
  /// InheritedPresentumResolvedVariant.of<MyResolvedVariant, MySurface, MyVisualVariant>(context);
  /// ```
  static InheritedPresentumResolvedVariant<TResolved, S, V>? maybeOf<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = false}) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedPresentumResolvedVariant<TResolved, S, V>
            >()
      : context
            .getInheritedWidgetOfExactType<
              InheritedPresentumResolvedVariant<TResolved, S, V>
            >();

  @override
  bool updateShouldNotify(
    InheritedPresentumResolvedVariant<TResolved, S, V> oldWidget,
  ) => oldWidget.item != item;
}
