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

  /// Get the [InheritedPresentumResolvedVariant] instance from the context.
  static InheritedPresentumResolvedVariant<TResolved, S, V> of<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = false}) =>
      maybeOf<TResolved, S, V>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType();

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a InheritedPresentationItem of the exact type',
    'out_of_scope',
  );

  /// Get the [InheritedPresentumResolvedVariant] instance from the context, if
  /// it exists.
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
