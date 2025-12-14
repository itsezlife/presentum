import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentum.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

/// Extension methods for [BuildContext].
extension PresentumBuildContextExtension on BuildContext {
  /// Receives the [Presentum] instance from the elements tree.
  Presentum<TResolved, S, V> presentum<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentum.of<TResolved, S, V>(this, listen: false).presentum;

  /// Receives the [ResolvedPresentumVariant] instance from the elements tree.
  ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>
  resolvedPresentumVariant<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentumResolvedVariant.of<TResolved, S, V>(
    this,
    listen: false,
  ).item;

  /// Receives the [ResolvedPresentumVariant] instance from the elements tree.
  ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>
  watchedResolvedPresentumVariant<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentumResolvedVariant.of<TResolved, S, V>(
    this,
    listen: true,
  ).item;
}
