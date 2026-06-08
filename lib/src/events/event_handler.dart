import 'package:presentum/src/events/events.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template presentum_event_handler}
/// Handles presentation lifecycle events ([PresentumShownEvent], etc.).
/// {@endtemplate}
typedef PresentumEventHandler<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> = IPresentumEventHandler<TItem, S, V>;
