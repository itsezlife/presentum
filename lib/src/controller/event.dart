import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_event}
/// Event that can occur during presentation lifecycle.
/// {@endtemplate}
@immutable
abstract base class PresentumEvent<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_event}
  const PresentumEvent();

  /// The resolved variant that triggered the event.
  abstract final TResolved item;

  /// The timestamp of the event.
  abstract final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumEvent<TResolved, S, V> &&
          item == other.item &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(item, timestamp);

  @override
  String toString() => '$runtimeType(item: $item, timestamp: $timestamp)';
}

/// {@template presentum_shown_event}
/// Event when a presentation is shown.
/// {@endtemplate}
final class PresentumShownEvent<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TResolved, S, V> {
  /// {@macro presentum_shown_event}
  const PresentumShownEvent({required this.item, required this.timestamp});

  @override
  final TResolved item;

  @override
  final DateTime timestamp;
}

/// {@template presentum_dismissed_event}
/// Event when a presentation is dismissed.
/// {@endtemplate}
final class PresentumDismissedEvent<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TResolved, S, V> {
  /// {@macro presentum_dismissed_event}
  const PresentumDismissedEvent({required this.item, required this.timestamp});

  @override
  final TResolved item;

  @override
  final DateTime timestamp;
}

/// {@template presentum_converted_event}
/// Event when a presentation is converted.
/// {@endtemplate}
@immutable
final class PresentumConvertedEvent<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TResolved, S, V> {
  /// {@macro presentum_converted_event}
  const PresentumConvertedEvent({
    required this.item,
    required this.timestamp,
    this.conversionMetadata,
  });

  @override
  final TResolved item;

  @override
  final DateTime timestamp;

  /// Arbitrary metadata about the conversion.
  final Map<String, Object?>? conversionMetadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumConvertedEvent<TResolved, S, V> &&
          item == other.item &&
          timestamp == other.timestamp &&
          conversionMetadata == other.conversionMetadata;

  @override
  int get hashCode => Object.hash(item, timestamp, conversionMetadata);

  @override
  String toString() =>
      'PresentumConvertedEvent(item: $item, timestamp: $timestamp, '
      'conversionMetadata: $conversionMetadata)';
}

/// {@template presentum_event_handler}
/// Event handler for presentation events.
/// {@endtemplate}
abstract interface class IPresentumEventHandler<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_event_handler}
  const IPresentumEventHandler();

  /// Called when any presentation event occurs
  FutureOr<void> onEvent(PresentumEvent<TResolved, S, V> event);
}

/// {@template presentum_storage_event_handler}
/// Event handler for the presentum storage.
/// {@endtemplate}
final class PresentumStorageEventHandler<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements IPresentumEventHandler<TResolved, S, V> {
  /// {@macro presentum_storage_event_handler}
  const PresentumStorageEventHandler({required this.storage});

  /// The storage used by to store data about dismissals/conversions/shown
  /// items.
  final PresentumStorage<S, V> storage;

  @override
  FutureOr<void> onEvent(PresentumEvent<TResolved, S, V> event) async {
    switch (event) {
      case PresentumShownEvent(:final item, :final timestamp):
        await storage.recordShown(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.visualVariant,
        );
      case PresentumDismissedEvent(:final item, :final timestamp):
        await storage.recordDismissed(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.visualVariant,
        );
      case PresentumConvertedEvent(:final item, :final timestamp):
        await storage.recordConverted(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.visualVariant,
        );
    }
  }
}
