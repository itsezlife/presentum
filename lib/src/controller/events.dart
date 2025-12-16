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
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_event}
  const PresentumEvent();

  /// The presentum item that triggered the event.
  abstract final TItem item;

  /// The timestamp of the event.
  abstract final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumEvent<TItem, S, V> &&
          item == other.item &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(item, timestamp);

  @override
  String toString() => '$runtimeType(item: $item, timestamp: $timestamp)';
}

/// {@template presentum_shown_event}
/// Event when a presentation item is shown.
/// {@endtemplate}
final class PresentumShownEvent<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TItem, S, V> {
  /// {@macro presentum_shown_event}
  const PresentumShownEvent({required this.item, required this.timestamp});

  @override
  final TItem item;

  @override
  final DateTime timestamp;
}

/// {@template presentum_dismissed_event}
/// Event when a presentation item is dismissed.
/// {@endtemplate}
final class PresentumDismissedEvent<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TItem, S, V> {
  /// {@macro presentum_dismissed_event}
  const PresentumDismissedEvent({required this.item, required this.timestamp});

  @override
  final TItem item;

  @override
  final DateTime timestamp;
}

/// {@template presentum_converted_event}
/// Event when a presentation item is converted.
/// {@endtemplate}
@immutable
final class PresentumConvertedEvent<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEvent<TItem, S, V> {
  /// {@macro presentum_converted_event}
  const PresentumConvertedEvent({
    required this.item,
    required this.timestamp,
    this.conversionMetadata,
  });

  @override
  final TItem item;

  @override
  final DateTime timestamp;

  /// Arbitrary metadata about the conversion.
  final Map<String, Object?>? conversionMetadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumConvertedEvent<TItem, S, V> &&
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
/// Event handler for presentation item events.
/// {@endtemplate}
abstract interface class IPresentumEventHandler<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_event_handler}
  const IPresentumEventHandler();

  /// Called when any presentation item event occurs
  FutureOr<void> call(PresentumEvent<TItem, S, V> event);
}

/// {@template presentum_storage_event_handler}
/// Event handler for the presentum storage.
/// {@endtemplate}
final class PresentumStorageEventHandler<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements IPresentumEventHandler<TItem, S, V> {
  /// {@macro presentum_storage_event_handler}
  const PresentumStorageEventHandler({required this.storage});

  /// The storage used by to store data about dismissals/conversions/shown
  /// items.
  final PresentumStorage<S, V> storage;

  @override
  FutureOr<void> call(PresentumEvent<TItem, S, V> event) async {
    switch (event) {
      case PresentumShownEvent(:final item, :final timestamp):
        await storage.recordShown(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.variant,
        );
      case PresentumDismissedEvent(:final item, :final timestamp):
        await storage.recordDismissed(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.variant,
        );
      case PresentumConvertedEvent(:final item, :final timestamp):
        await storage.recordConverted(
          item.id,
          at: timestamp,
          surface: item.surface,
          variant: item.variant,
        );
    }
  }
}
