import 'package:presentum/src/events/event_handler.dart';
import 'package:presentum/src/events/events.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';

/// {@template presentum_lifecycle}
/// Atomic helpers that keep slot updates and storage/events in sync.
/// {@endtemplate}
abstract final class PresentumLifecycle {
  const PresentumLifecycle._();

  /// Records a shown impression — storage and [handlers] only; slots unchanged.
  static Future<void> shown<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >({
    required TItem item,
    required PresentumStorage<S, V> storage,
    List<PresentumEventHandler<TItem, S, V>> handlers = const [],
    DateTime? at,
  }) async {
    final timestamp = at ?? DateTime.now();
    final event = PresentumShownEvent<TItem, S, V>(
      item: item,
      timestamp: timestamp,
    );

    await storage.recordShown(
      item.id,
      at: timestamp,
      surface: item.surface,
      variant: item.variant,
    );
    await _dispatch(handlers, event);
  }

  /// Dismisses [surface]: updates slots, storage, and [handlers].
  ///
  /// Returns new slots for the host to emit.
  static Future<PresentumSlotState<TItem, S, V>> dismiss<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >({
    required PresentumSlotState<TItem, S, V> slots,
    required S surface,
    required TItem item,
    required PresentumStorage<S, V> storage,
    List<PresentumEventHandler<TItem, S, V>> handlers = const [],
    DateTime? at,
  }) async {
    final timestamp = at ?? DateTime.now();
    final newSlots = slots.withDismissed(surface);
    final event = PresentumDismissedEvent<TItem, S, V>(
      item: item,
      timestamp: timestamp,
    );

    await storage.recordDismissed(
      item.id,
      at: timestamp,
      surface: item.surface,
      variant: item.variant,
    );
    await _dispatch(handlers, event);

    return newSlots;
  }

  /// Records a conversion — storage and [handlers] only; slots unchanged.
  static Future<void> converted<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >({
    required TItem item,
    required PresentumStorage<S, V> storage,
    List<PresentumEventHandler<TItem, S, V>> handlers = const [],
    DateTime? at,
    Map<String, Object?>? conversionMetadata,
  }) async {
    final timestamp = at ?? DateTime.now();
    final event = PresentumConvertedEvent<TItem, S, V>(
      item: item,
      timestamp: timestamp,
      conversionMetadata: conversionMetadata,
    );

    await storage.recordConverted(
      item.id,
      at: timestamp,
      surface: item.surface,
      variant: item.variant,
    );
    await _dispatch(handlers, event);
  }

  static Future<void> _dispatch<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(
    List<PresentumEventHandler<TItem, S, V>> handlers,
    PresentumEvent<TItem, S, V> event,
  ) async {
    for (final handler in handlers) {
      await handler(event);
    }
  }
}
