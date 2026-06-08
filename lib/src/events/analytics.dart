import 'dart:async';

import 'package:presentum/src/events/event_handler.dart';
import 'package:presentum/src/events/events.dart';
import 'package:presentum/src/events/presentum_analytics_impl.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template presentum_analytics}
/// App-defined analytics port — implement once, reuse across domains.
/// {@endtemplate}
abstract class PresentumAnalytics<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_analytics}
  const PresentumAnalytics();

  /// Creates analytics from inline callbacks.
  factory PresentumAnalytics.fromFunctions({
    required FutureOr<void> Function(PresentumShownEvent<TItem, S, V> event)
    onShown,
    required FutureOr<void> Function(PresentumDismissedEvent<TItem, S, V> event)
    onDismissed,
    required FutureOr<void> Function(PresentumConvertedEvent<TItem, S, V> event)
    onConverted,
  }) => PresentumAnalytics$Impl<TItem, S, V>(
    onShown: onShown,
    onDismissed: onDismissed,
    onConverted: onConverted,
  );

  /// Called when a presentation item is shown.
  FutureOr<void> onShown(PresentumShownEvent<TItem, S, V> event);

  /// Called when a presentation item is dismissed.
  FutureOr<void> onDismissed(PresentumDismissedEvent<TItem, S, V> event);

  /// Called when a presentation item converts.
  FutureOr<void> onConverted(PresentumConvertedEvent<TItem, S, V> event);
}

/// {@template presentum_analytics_event_handler}
/// Routes lifecycle events to a [PresentumAnalytics] port.
/// {@endtemplate}
final class PresentumAnalyticsEventHandler<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements PresentumEventHandler<TItem, S, V> {
  /// {@macro presentum_analytics_event_handler}
  const PresentumAnalyticsEventHandler({
    required PresentumAnalytics<TItem, S, V> analytics,
  }) : _analytics = analytics;

  final PresentumAnalytics<TItem, S, V> _analytics;

  @override
  FutureOr<void> call(PresentumEvent<TItem, S, V> event) {
    switch (event) {
      case PresentumShownEvent<TItem, S, V>():
        return _analytics.onShown(event);
      case PresentumDismissedEvent<TItem, S, V>():
        return _analytics.onDismissed(event);
      case PresentumConvertedEvent<TItem, S, V>():
        return _analytics.onConverted(event);
    }
  }
}
