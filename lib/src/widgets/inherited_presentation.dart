import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Inherited presentum widget.
class InheritedPresentum<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends InheritedWidget {
  /// {@macro inherited_presentum}
  const InheritedPresentum({
    required this.presentum,
    required super.child,
    super.key,
  });

  /// {@macro inherited_presentum.value}
  const InheritedPresentum.value({
    required Presentum<TResolved, S, V> value,
    required super.child,
    super.key,
  }) : presentum = value;

  /// Receives the [Presentum] instance from the elements tree.
  final Presentum<TResolved, S, V> presentum;

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a InheritedPresentum of the exact type',
    'out_of_scope',
  );

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `InheritedPresentum.maybeOf(context)`.
  static InheritedPresentum<TResolved, S, V>? maybeOf<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = true}) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedPresentum<TResolved, S, V>
            >()
      : context
            .getInheritedWidgetOfExactType<
              InheritedPresentum<TResolved, S, V>
            >();

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `InheritedPresentum.of(context)`
  static InheritedPresentum<TResolved, S, V> of<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = true}) =>
      maybeOf<TResolved, S, V>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(
    covariant InheritedPresentum<TResolved, S, V> oldWidget,
  ) => false;
}
