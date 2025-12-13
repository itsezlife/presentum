import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/guard.dart';
import 'package:presentum/src/state/payload.dart';

/// Null object reference for copyWith method to distinguish null state updates
/// from no new state updates.
///
/// If nothing is passed to the copyWith method for the state value, the null
/// object is determined as no updates. If null was introduces, it'll set the
/// state value to literal null.
const Object _null = {};

/// [PresentumState$Mutable] intention to change and update state at
/// application.
enum PresentumStateIntention {
  /// Does not have a specific intention.
  /// The presentum generates a new presentation information every time it
  /// detects presentation information may have change due to a rebuild.
  /// This is the default intention.
  auto('auto'),

  /// Update application state and replace presentation information.
  replace('replace'),

  /// Update application state.
  append('append'),

  /// Do nothing. This is especially useful at [PresentumGuard]s
  /// to cancel and interrupt state transition and do nothing.
  cancel('cancel');

  const PresentumStateIntention(this.name);

  /// The name of the intention.
  final String name;

  /// Parse the name of the intention.
  static PresentumStateIntention fromName(String? value) => switch (value) {
    'auto' => PresentumStateIntention.auto,
    'replace' => PresentumStateIntention.replace,
    'append' => PresentumStateIntention.append,
    'cancel' => PresentumStateIntention.cancel,
    _ => PresentumStateIntention.auto,
  };
}

/// Marker for all presentum surfaces.
///
/// Implement this on your surface enums:
/// `enum AppSurface with PresentumSurface { ... }`
mixin PresentumSurface on Enum {
  /// The key of the surface.
  String get key => name;
}

/// Marker for all presentum variants.
///
/// Implement this on your surface enums:
/// `enum AppVariant with PresentumVariant { ... }`
mixin PresentumVisualVariant on Enum {
  /// The key of the surface.
  String get key => name;
}

/// {@template presentum_slot}
/// A presentation slot is the per‑surface queue:
/// - one `active` resolved item,
/// - a FIFO (First In, First Out) `queue` of additional items.
/// {@endtemplate}
@immutable
class PresentumSlot<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_slot}
  const PresentumSlot({
    required this.surface,
    required this.active,
    required this.queue,
  });

  /// Empty slot.
  ///
  /// {@macro slot}
  const PresentumSlot.empty(this.surface) : active = null, queue = const [];

  /// The surface of the slot.
  final S surface;

  /// The active item of the slot.
  final TResolved? active;

  /// The queue of the slot.
  final List<TResolved> queue;

  /// Create a copy of the slot with the given changes.
  PresentumSlot<TResolved, S, V> copyWith({
    Object? active = _null,
    List<TResolved>? queue,
  }) => PresentumSlot<TResolved, S, V>(
    surface: surface,
    active: active == _null ? this.active : active as TResolved?,
    queue: queue ?? this.queue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentumSlot<TResolved, S, V> &&
        other.surface == surface &&
        other.active == active &&
        other.queue == queue;
  }

  @override
  int get hashCode => Object.hash(surface, active, queue);
}

/// Signature for the callback to [PresentumState.visitSlots].
///
/// The arguments are the surface and the slot being visited.
///
/// It is safe to call `state.visitSlots` reentrantly within
/// this callback.
///
/// Return false to stop the walk.
typedef ConditionalSlotVisitor<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> = bool Function(S surface, PresentumSlot<TResolved, S, V> slot);

/// Sealed root type for presentation state.
sealed class PresentumState<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumStateBase<TResolved, S, V> {
  factory PresentumState({
    required Map<S, PresentumSlot<TResolved, S, V>> slots,
    required PresentumStateIntention intention,
  }) = PresentumState$Mutable<TResolved, S, V>;

  PresentumState._();

  /// Create state from list of nodes
  ///
  /// {@macro presentum_state}
  @factory
  static PresentumState$Mutable<TResolved, S, V> from<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(PresentumState<TResolved, S, V> state) =>
      PresentumState$Mutable<TResolved, S, V>.from(state);

  /// Empty state
  ///
  /// {@macro presentum_state}
  @factory
  static PresentumState$Mutable<TResolved, S, V> empty<
    TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >({PresentumStateIntention intention = PresentumStateIntention.auto}) =>
      PresentumState$Mutable<TResolved, S, V>(
        slots: <S, PresentumSlot<TResolved, S, V>>{},
        intention: intention,
      );

  /// Returns a immutable copy of this state.
  @override
  PresentumState$Immutable<TResolved, S, V> freeze();

  /// Returns a mutable copy of this state.
  @override
  PresentumState$Mutable<TResolved, S, V> mutate();

  /// Returns all active items across all slots.
  List<TResolved> get activeItems =>
      slots.values.map((e) => e.active).whereType<TResolved>().toList();

  @override
  String toString();
}

/// {@macro presentum_state}
@immutable
final class PresentumState$Immutable<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumState<TResolved, S, V>
    with _PresentumStateBase$Immutable<TResolved, S, V> {
  /// {@macro presentum_state}
  factory PresentumState$Immutable({
    required Map<S, PresentumSlot<TResolved, S, V>> slots,
    required PresentumStateIntention intention,
  }) => PresentumState$Immutable._(
    slots: UnmodifiableMapView<S, PresentumSlot<TResolved, S, V>>(slots),
    intention: intention,
  );

  /// {@macro presentum_state}
  factory PresentumState$Immutable.from(
    PresentumState<TResolved, S, V> state,
  ) => state is PresentumState$Immutable<TResolved, S, V>
      ? state
      : PresentumState$Immutable(
          slots: state.slots,
          intention: state.intention,
        );

  PresentumState$Immutable._({
    required Map<S, PresentumSlot<TResolved, S, V>> slots,
    required this.intention,
  }) : _slots = UnmodifiableMapView<S, PresentumSlot<TResolved, S, V>>(slots),
       super._();

  final Map<S, PresentumSlot<TResolved, S, V>> _slots;

  @override
  Map<S, PresentumSlot<TResolved, S, V>> get slots => _slots;

  @override
  final PresentumStateIntention intention;

  @override
  PresentumState$Immutable<TResolved, S, V> freeze() => this;

  @override
  PresentumState$Mutable<TResolved, S, V> mutate() =>
      PresentumState$Mutable<TResolved, S, V>(
        slots: Map<S, PresentumSlot<TResolved, S, V>>.of(_slots),
        intention: intention,
      );

  @override
  PresentumState$Immutable<TResolved, S, V> copy() =>
      PresentumState$Immutable<TResolved, S, V>(
        slots: _slots,
        intention: intention,
      );

  /// Returns all surfaces that have an active item.
  Iterable<S> get activeSurfaces sync* {
    for (final entry in _slots.entries) {
      if (entry.value.active != null) yield entry.key;
    }
  }

  /// Serialize using injected encoders (keeps engine generic).
  Map<String, Object?> toJson({
    required Map<String, Object?> Function(TResolved item) encodeItem,
  }) => <String, Object?>{
    'intention': intention.name,
    'slots': <Map<String, Object?>>[
      for (final entry in _slots.entries)
        <String, Object?>{
          'surface': entry.key.name,
          'active': entry.value.active == null
              ? null
              : encodeItem(entry.value.active as TResolved),
          'queue': <Map<String, Object?>>[
            for (final q in entry.value.queue) encodeItem(q),
          ],
        },
    ],
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentumState$Immutable<TResolved, S, V> &&
        MapEquality<S, PresentumSlot<TResolved, S, V>>().equals(
          slots,
          other.slots,
        ) &&
        intention == other.intention;
  }

  @override
  int get hashCode => Object.hash(
    MapEquality<S, PresentumSlot<TResolved, S, V>>().hash(slots),
    intention,
  );

  @override
  String toString() =>
      'PresentumState\$Immutable(slots: $slots, intention: $intention)';
}

/// Mutable state.
final class PresentumState$Mutable<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumState<TResolved, S, V>
    with _PresentumStateBase$Mutable<TResolved, S, V> {
  /// {@macro presentum_state}
  PresentumState$Mutable({
    Map<S, PresentumSlot<TResolved, S, V>>? slots,
    this.intention = PresentumStateIntention.auto,
  }) : _slots = slots ?? <S, PresentumSlot<TResolved, S, V>>{},
       super._();

  /// {@macro presentum_state}
  factory PresentumState$Mutable.from(PresentumState<TResolved, S, V> state) =>
      PresentumState$Mutable<TResolved, S, V>(
        slots: state.slots,
        intention: state.intention,
      );

  final Map<S, PresentumSlot<TResolved, S, V>> _slots;

  @override
  Map<S, PresentumSlot<TResolved, S, V>> get slots => _slots;

  @override
  PresentumStateIntention intention;

  @override
  PresentumState$Immutable<TResolved, S, V> freeze() =>
      PresentumState$Immutable<TResolved, S, V>(
        slots: _slots,
        intention: intention,
      );

  @override
  PresentumState$Mutable<TResolved, S, V> mutate() => this;

  @override
  PresentumState$Mutable<TResolved, S, V> copy() =>
      PresentumState$Mutable<TResolved, S, V>(
        slots: Map<S, PresentumSlot<TResolved, S, V>>.of(_slots),
        intention: intention,
      );

  /// Add new item to the end of the queue for the specified surface.
  void add(S surface, TResolved item) {
    final slot = _ensureSlot(surface);

    final hasActive = slot.active != null;
    _slots[surface] = slot.copyWith(
      active: hasActive ? slot.active : item,
      queue: hasActive ? [...slot.queue, item] : slot.queue,
    );
  }

  /// Add multiple items to the end of the queue for the specified surface.
  void addAll(S surface, List<TResolved> items) {
    if (items.isEmpty) return;
    final slot = _ensureSlot(surface);
    final hasActive = slot.active != null;
    _slots[surface] = slot.copyWith(
      active: hasActive ? slot.active : items.first,
      queue: hasActive
          ? [...slot.queue, ...items]
          : [...slot.queue, ...items.sublist(1)],
    );
  }

  /// Insert item at the specified index in the queue for the specified surface.
  void insert(S surface, int index, TResolved item) {
    final slot = _ensureSlot(surface);
    final hasActive = slot.active != null;
    final queue = List<TResolved>.from(slot.queue);

    if (hasActive) {
      queue.insert(index, item);
      _slots[surface] = slot.copyWith(queue: queue);
    } else {
      _slots[surface] = slot.copyWith(active: item, queue: queue);
    }
  }

  /// Insert multiple items at the specified index in the queue for the
  /// specified surface.
  void insertAll(S surface, int index, List<TResolved> items) {
    if (items.isEmpty) return;
    final slot = _ensureSlot(surface);
    final hasActive = slot.active != null;

    final queue = List<TResolved>.from(slot.queue);
    if (hasActive) {
      queue.insertAll(index, items);
      _slots[surface] = slot.copyWith(queue: queue);
    } else {
      queue.insertAll(index, items.sublist(1));
      _slots[surface] = slot.copyWith(active: items.first, queue: queue);
    }
  }

  /// Returns true if [surface] has an active item.
  bool hasActive(S surface) => _slots[surface]?.active != null;

  /// Ensure slot exists and return it.
  PresentumSlot<TResolved, S, V> _ensureSlot(S surface) =>
      _slots[surface] ??= PresentumSlot.empty(surface);

  /// Set active item for [surface] using [intention] semantics.
  Map<S, PresentumSlot<TResolved, S, V>> setActive(
    S surface,
    TResolved item, {
    PresentumStateIntention intention = PresentumStateIntention.replace,
  }) {
    final current = _ensureSlot(surface);
    switch (intention) {
      case PresentumStateIntention.replace:
        _slots[surface] = current.copyWith(active: item, queue: []);
      case PresentumStateIntention.append:
        _slots[surface] = current.copyWith(
          active: current.active ?? item,
          queue: current.active == null
              ? current.queue
              : <TResolved>[...current.queue, item],
        );
      case PresentumStateIntention.auto:
      case PresentumStateIntention.cancel:
        _slots[surface] = current.copyWith(active: item);
    }
    return Map<S, PresentumSlot<TResolved, S, V>>.from(_slots);
  }

  /// Clear active item from [surface] and promote next queued item if
  /// available.
  PresentumSlot<TResolved, S, V>? clearActive(S surface) {
    final slot = _slots[surface];
    if (slot == null) return null;

    // If there are queued items, promote the first one to active
    if (slot.queue.isNotEmpty) {
      final nextItem = slot.queue.first;
      final remainingQueue = List<TResolved>.of(slot.queue)..removeAt(0);
      _slots[surface] = slot.copyWith(active: nextItem, queue: remainingQueue);
    } else {
      // No queued items, just clear active
      _slots[surface] = slot.copyWith(active: null);
    }
    return _slots[surface];
  }

  /// Enqueue an item to [surface] queue (preserves active).
  void enqueue(S surface, TResolved item) {
    final slot = _ensureSlot(surface);
    final updated = <TResolved>[...slot.queue, item];
    _slots[surface] = slot.copyWith(queue: updated);
  }

  /// Dequeue first queued item from [surface].
  TResolved? dequeue(S surface) {
    final slot = _slots[surface];
    if (slot == null || slot.queue.isEmpty) return null;
    final updated = List<TResolved>.of(slot.queue)..removeAt(0);
    _slots[surface] = slot.copyWith(queue: updated);
    return slot.queue.first;
  }

  /// Get a copy of queue for [surface].
  List<TResolved> queueOf(S surface) =>
      List<TResolved>.of(_slots[surface]?.queue ?? <TResolved>[]);

  /// Replace queue for [surface].
  void setQueue(S surface, List<TResolved> items) {
    final slot = _ensureSlot(surface);
    _slots[surface] = slot.copyWith(queue: List<TResolved>.of(items));
  }

  /// Clear the active and queue for a surface.
  PresentumSlot<TResolved, S, V>? clearSurface(S surface) {
    if (!_slots.containsKey(surface)) return null;
    final emptySlot = PresentumSlot<TResolved, S, V>.empty(surface);
    _slots[surface] = emptySlot;
    return emptySlot;
  }

  /// Remove all slots.
  void clearAll() => _slots.clear();

  /// Remove items matching the predicate from both active and queue positions.
  /// This preserves items from other campaigns while removing only ineligible
  /// ones. If active item is removed and queue has items, promotes next queued
  /// item.
  Map<S, PresentumSlot<TResolved, S, V>> removeWhere(
    bool Function(TResolved item) predicate,
  ) {
    for (final entry in _slots.entries) {
      final surface = entry.key;
      final slot = entry.value;

      // Check if active item should be removed
      var newActive = slot.active;
      var activeRemoved = false;
      if (slot.active case final active? when predicate(active)) {
        newActive = null;
        activeRemoved = true;
      }

      // Filter queue to remove matching items
      final newQueue = slot.queue.where((item) => !predicate(item)).toList();

      // If active was removed and there are remaining queued items, promote
      // the first one
      if (activeRemoved && newQueue.isNotEmpty) {
        newActive = newQueue.removeAt(0);
      }

      // Update slot if anything changed
      if (newActive != slot.active || newQueue.length != slot.queue.length) {
        final newSlot = slot.copyWith(active: newActive, queue: newQueue);

        // If the slot is empty, has no active item and no queue, remove it.
        if (newSlot.active == null && newSlot.queue.isEmpty) {
          _slots.remove(surface);
        } else {
          _slots[surface] = newSlot;
        }
      }
    }
    return Map<S, PresentumSlot<TResolved, S, V>>.from(_slots);
  }

  /// Remove items from specific surface matching the predicate.
  /// If active item is removed and queue has items, promotes next queued item.
  PresentumSlot<TResolved, S, V>? removeFromSurface(
    S surface,
    bool Function(TResolved item) predicate,
  ) {
    final slot = _slots[surface];
    if (slot == null) return null;

    // Check if active item should be removed
    var newActive = slot.active;
    var activeRemoved = false;
    if (slot.active case final active? when predicate(active)) {
      newActive = null;
      activeRemoved = true;
    }

    // Filter queue to remove matching items
    final newQueue = slot.queue.where((item) => !predicate(item)).toList();

    // If active was removed and there are remaining queued items, promote
    // the first one
    if (activeRemoved && newQueue.isNotEmpty) {
      newActive = newQueue.removeAt(0);
    }

    // Update slot if anything changed
    if (newActive != slot.active || newQueue.length != slot.queue.length) {
      final newSlot = slot.copyWith(active: newActive, queue: newQueue);

      // If the slot is empty, has no active item and no queue, remove it.
      if (newSlot.active == null && newSlot.queue.isEmpty) {
        _slots.remove(surface);
      } else {
        _slots[surface] = newSlot;
      }
    }

    return _slots[surface];
  }

  /// Look up the slot with [surface], or add a new slot if it isn't there.
  PresentumSlot<TResolved, S, V> putIfAbsent(
    S surface,
    PresentumSlot<TResolved, S, V> Function() ifAbsent,
  ) => _slots.putIfAbsent(surface, ifAbsent);

  /// Remove items with matching [id] from slots.
  ///
  /// If [surface] is provided, only that surface is affected.
  Map<S, PresentumSlot<TResolved, S, V>> removeById(String id, {S? surface}) {
    if (surface != null) {
      removeFromSurface(surface, (item) => item.id == id);
      return Map<S, PresentumSlot<TResolved, S, V>>.from(slots);
    }
    return removeWhere((item) => item.id == id);
  }

  /// Returns true if any slot contains an item with the given [id].
  bool containsId(String id, {S? surface}) {
    if (surface != null) {
      final slot = slots[surface];
      if (slot == null) return false;
      if (slot.active?.id == id) return true;
      return slot.queue.any((item) => item.id == id);
    }

    var found = false;
    visitSlots((s, slot) {
      if (slot.active?.id == id || slot.queue.any((item) => item.id == id)) {
        found = true;
        return false; // Stop the walk
      }
      return true; // Continue the walk
    });
    return found;
  }
}

/// Base class for presentation state implementations.
abstract base class PresentumStateBase<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// Returns true if this entity has children.
  bool get hasSlots => slots.isNotEmpty;

  /// Returns a immutable copy of this entity.
  PresentumStateBase<TResolved, S, V> freeze();

  /// Returns a mutable copy of this entity.
  PresentumStateBase<TResolved, S, V> mutate();

  /// Returns a copy of this entity (keeps mutability).
  PresentumStateBase<TResolved, S, V> copy();

  /// The slots of the state.
  abstract final Map<S, PresentumSlot<TResolved, S, V>> slots;

  /// The intention of the state.
  abstract final PresentumStateIntention intention;

  /// Walks the slots of this state.
  ///
  /// Return false to stop the walk.
  void visitSlots(ConditionalSlotVisitor<TResolved, S, V> visitor);

  /// Search slot by surface and get first match or null.
  PresentumSlot<TResolved, S, V>? findSlot(
    ConditionalSlotVisitor<TResolved, S, V> test,
  );

  /// Search all slots that match the test condition.
  List<PresentumSlot<TResolved, S, V>> findAllSlots(
    ConditionalSlotVisitor<TResolved, S, V> test,
  );

  /// Walks the slots of this state and evaluates [value] on each of them.
  T foldSlots<T>(
    T value,
    T Function(T value, S surface, PresentumSlot<TResolved, S, V> slot) visitor,
  );
}

base mixin _PresentumStateBase$Mutable<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    on PresentumStateBase<TResolved, S, V> {
  @override
  void visitSlots(ConditionalSlotVisitor<TResolved, S, V> visitor) {
    for (final entry in slots.entries) {
      if (!visitor(entry.key, entry.value)) return;
    }
  }

  @override
  PresentumSlot<TResolved, S, V>? findSlot(
    ConditionalSlotVisitor<TResolved, S, V> test,
  ) {
    for (final entry in slots.entries) {
      if (test(entry.key, entry.value)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  List<PresentumSlot<TResolved, S, V>> findAllSlots(
    ConditionalSlotVisitor<TResolved, S, V> test,
  ) {
    final result = <PresentumSlot<TResolved, S, V>>[];
    for (final entry in slots.entries) {
      if (test(entry.key, entry.value)) {
        result.add(entry.value);
      }
    }
    return result;
  }

  @override
  T foldSlots<T>(
    T value,
    T Function(T value, S surface, PresentumSlot<TResolved, S, V> slot) visitor,
  ) {
    var result = value;
    for (final entry in slots.entries) {
      result = visitor(result, entry.key, entry.value);
    }
    return result;
  }
}

base mixin _PresentumStateBase$Immutable<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    on PresentumStateBase<TResolved, S, V> {
  @override
  void visitSlots(ConditionalSlotVisitor<TResolved, S, V> visitor) {
    for (final entry in slots.entries) {
      if (!visitor(entry.key, entry.value)) return;
    }
  }

  @override
  PresentumSlot<TResolved, S, V>? findSlot(
    ConditionalSlotVisitor<TResolved, S, V> test,
  ) {
    for (final entry in slots.entries) {
      if (test(entry.key, entry.value)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  List<PresentumSlot<TResolved, S, V>> findAllSlots(
    ConditionalSlotVisitor<TResolved, S, V> test,
  ) {
    final result = <PresentumSlot<TResolved, S, V>>[];
    for (final entry in slots.entries) {
      if (test(entry.key, entry.value)) {
        result.add(entry.value);
      }
    }
    return result;
  }

  @override
  T foldSlots<T>(
    T value,
    T Function(T value, S surface, PresentumSlot<TResolved, S, V> slot) visitor,
  ) {
    var result = value;
    for (final entry in slots.entries) {
      result = visitor(result, entry.key, entry.value);
    }
    return result;
  }
}
