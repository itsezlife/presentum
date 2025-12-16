// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_item_context}
/// Inherited widget that provides the [PresentumItem] instance
/// to the widget tree.
/// {@endtemplate}
class InheritedPresentumItem<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends InheritedWidget {
  /// {@macro presentum_item_context}
  const InheritedPresentumItem({
    required this.item,
    required super.child,
    super.key,
  });

  /// The presentum item that is being presented.
  final TItem item;

  /// Method that allows widgets to access a [PresentumItem] instance
  /// as long as their `BuildContext` contains an
  /// [InheritedPresentumItem] instance.
  ///
  /// If we want to access an instance of a presentum item which was
  /// provided higher up in the widget tree we can do so via:
  ///
  /// ```dart
  /// InheritedPresentumItem.of<MyItem, MySurface, MyVisual>(context);
  /// ```
  static InheritedPresentumItem<TItem, S, V> of<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = false}) =>
      maybeOf<TItem, S, V>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType<TItem, S, V>();

  static Never _notFoundInheritedWidgetOfExactType<TItem, S, V>() =>
      throw FlutterError('''
      InheritedPresentumItem.of<$TItem, $S, $V>() called with a context that does 
      not contain a presentum item.
      No ancestor could be found starting from the context that was passed to 
      InheritedPresentumItem.of<$TItem, $S, $V>().

      This can happen if the context you used comes from a widget above the InheritedPresentumItem<$TItem, $S, $V>().

      To fix this:
      1. Make sure your widget is wrapped with an InheritedPresentumItem<$TItem, $S, $V>()
      2. Ensure the generic types match exactly between the provider and consumer
      3. Check that the context comes from a widget below the InheritedPresentumItem<$TItem, $S, $V>() in the widget tree
    ''');

  /// Method that allows widgets to access a [PresentumItem] instance
  /// as long as their `BuildContext` contains an
  /// [InheritedPresentumItem] instance.
  ///
  /// If we want to access an instance of a presentum item which was
  /// provided higher up in the widget tree we can do so via:
  ///
  /// ```dart
  /// InheritedPresentumItem.of<MyItem, MySurface, MyVisual>(context);
  /// ```
  static InheritedPresentumItem<TItem, S, V>? maybeOf<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = false}) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedPresentumItem<TItem, S, V>
            >()
      : context
            .getInheritedWidgetOfExactType<
              InheritedPresentumItem<TItem, S, V>
            >();

  @override
  bool updateShouldNotify(InheritedPresentumItem<TItem, S, V> oldWidget) =>
      oldWidget.item != item;
}
