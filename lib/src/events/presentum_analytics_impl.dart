import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/events/analytics.dart';
import 'package:presentum/src/events/events.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

@internal
final class PresentumAnalytics$Impl<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumAnalytics<TItem, S, V> {
  const PresentumAnalytics$Impl({
    required FutureOr<void> Function(PresentumShownEvent<TItem, S, V> event)
    onShown,
    required FutureOr<void> Function(PresentumDismissedEvent<TItem, S, V> event)
    onDismissed,
    required FutureOr<void> Function(PresentumConvertedEvent<TItem, S, V> event)
    onConverted,
  }) : _$onShown = onShown,
       _$onDismissed = onDismissed,
       _$onConverted = onConverted;

  final FutureOr<void> Function(PresentumShownEvent<TItem, S, V> event)
  _$onShown;
  final FutureOr<void> Function(PresentumDismissedEvent<TItem, S, V> event)
  _$onDismissed;
  final FutureOr<void> Function(PresentumConvertedEvent<TItem, S, V> event)
  _$onConverted;

  @nonVirtual
  @override
  FutureOr<void> onShown(PresentumShownEvent<TItem, S, V> event) =>
      _$onShown(event);

  @nonVirtual
  @override
  FutureOr<void> onDismissed(PresentumDismissedEvent<TItem, S, V> event) =>
      _$onDismissed(event);

  @nonVirtual
  @override
  FutureOr<void> onConverted(PresentumConvertedEvent<TItem, S, V> event) =>
      _$onConverted(event);
}
