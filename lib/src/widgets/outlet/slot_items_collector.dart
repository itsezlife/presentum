import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template presentum_slot_items_collector}
/// Selects which items from a surface slot an outlet should render.
/// {@endtemplate}
abstract class PresentumSlotItemsCollector<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_slot_items_collector}
  const PresentumSlotItemsCollector();

  /// Returns only the first slot item (active, else queue head).
  const factory PresentumSlotItemsCollector.single() =
      PresentumSlotItemsCollector$Single<TItem, S, V>;

  /// Returns active + queue in order.
  const factory PresentumSlotItemsCollector.all() =
      PresentumSlotItemsCollector$All<TItem, S, V>;

  /// Applies [select] to active + queue items.
  factory PresentumSlotItemsCollector.custom(
    List<TItem> Function(List<TItem> slotItems) select,
  ) => PresentumSlotItemsCollector$Custom<TItem, S, V>(select);

  /// Active item followed by queue entries for [surface].
  @protected
  List<TItem> readSlotItems(PresentumSlotState<TItem, S, V> slots, S surface) {
    final active = slots.activeFor(surface);
    final queue = slots.queueFor(surface);
    return [?active, ...queue];
  }

  /// Items to pass to an outlet builder for [surface].
  List<TItem> collect(PresentumSlotState<TItem, S, V> slots, S surface);
}

/// First item in the slot (active, else queue head).
final class PresentumSlotItemsCollector$Single<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumSlotItemsCollector<TItem, S, V> {
  /// {@macro presentum_slot_items_collector}
  const PresentumSlotItemsCollector$Single();

  @override
  List<TItem> collect(PresentumSlotState<TItem, S, V> slots, S surface) {
    final items = readSlotItems(slots, surface);
    if (items.isEmpty) return <TItem>[];
    return <TItem>[items.first];
  }
}

/// Active + full queue.
final class PresentumSlotItemsCollector$All<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumSlotItemsCollector<TItem, S, V> {
  /// {@macro presentum_slot_items_collector}
  const PresentumSlotItemsCollector$All();

  @override
  List<TItem> collect(PresentumSlotState<TItem, S, V> slots, S surface) =>
      readSlotItems(slots, surface);
}

/// User-defined selection over slot items.
final class PresentumSlotItemsCollector$Custom<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumSlotItemsCollector<TItem, S, V> {
  /// {@macro presentum_slot_items_collector}
  const PresentumSlotItemsCollector$Custom(this._select);

  final List<TItem> Function(List<TItem> slotItems) _select;

  @override
  List<TItem> collect(PresentumSlotState<TItem, S, V> slots, S surface) =>
      _select(readSlotItems(slots, surface));
}
