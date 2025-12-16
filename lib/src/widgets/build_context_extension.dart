import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentum.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

/// Extension methods for [BuildContext].
extension PresentumBuildContextExtension on BuildContext {
  /// Receives the [Presentum] instance from the elements tree.
  Presentum<TItem, S, V> presentum<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentum.of<TItem, S, V>(this, listen: false).presentum;

  /// Receives the [PresentumItem] instance from the elements tree.
  TItem presentumItem<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentumItem.of<TItem, S, V>(this, listen: false).item;

  /// Receives the [PresentumItem] instance from the elements tree.
  TItem watchPresentumItem<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >() => InheritedPresentumItem.of<TItem, S, V>(this, listen: true).item;
}
