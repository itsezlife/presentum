import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

/// Extension methods for [BuildContext].
extension PresentumBuildContextExtension on BuildContext {
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
