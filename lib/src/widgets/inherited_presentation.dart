import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Inherited presentum widget.
class InheritedPresentum<
  TResolved extends Identifiable,
  S extends PresentumSurface
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
    required Presentum<TResolved, S> value,
    required super.child,
    super.key,
  }) : presentum = value;

  /// Receives the [Presentum] instance from the elements tree.
  final Presentum<TResolved, S> presentum;

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
    'Out of scope, not found inherited widget '
        'a InheritedPresentum of the exact type',
    'out_of_scope',
  );

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `InheritedPresentum.maybeOf(context)`.
  static InheritedPresentum<TResolved, S>? maybeOf<
    TResolved extends Identifiable,
    S extends PresentumSurface
  >(BuildContext context, {bool listen = true}) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<
              InheritedPresentum<TResolved, S>
            >()
      : context
            .getInheritedWidgetOfExactType<InheritedPresentum<TResolved, S>>();

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `InheritedPresentum.of(context)`
  static InheritedPresentum<TResolved, S>
  of<TResolved extends Identifiable, S extends PresentumSurface>(
    BuildContext context, {
    bool listen = true,
  }) =>
      maybeOf<TResolved, S>(context, listen: listen) ??
      _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(
    covariant InheritedPresentum<TResolved, S> oldWidget,
  ) => false;
}
