import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Inherited presentum widget.
class InheritedPresentum<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
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
    required Presentum<TItem, S, V> value,
    required super.child,
    super.key,
  }) : presentum = value;

  /// Receives the [Presentum] instance from the elements tree.
  final Presentum<TItem, S, V> presentum;

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a InheritedPresentum of the exact type',
    'out_of_scope',
  );

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `InheritedPresentum.maybeOf(context)`.
  static InheritedPresentum<TItem, S, V>? maybeOf<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = true}) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedPresentum<TItem, S, V>
            >()
      : context
            .getInheritedWidgetOfExactType<InheritedPresentum<TItem, S, V>>();

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `InheritedPresentum.of(context)`
  static InheritedPresentum<TItem, S, V> of<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context, {bool listen = true}) =>
      maybeOf<TItem, S, V>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(
    covariant InheritedPresentum<TItem, S, V> oldWidget,
  ) => false;
}
