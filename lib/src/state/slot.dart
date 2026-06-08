import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

const Object _null = {};

/// {@template presentum_slot}
/// A presentation slot is the per‑surface queue:
/// - one `active` presentum item,
/// - a FIFO (First In, First Out) `queue` of additional items.
/// {@endtemplate}
@immutable
class PresentumSlot<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
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
  const PresentumSlot.empty(this.surface) : active = null, queue = const [];

  /// Create a slot from JSON.
  factory PresentumSlot.fromJson(
    Map<String, Object?> json, {
    required S Function(String surface) decodeSurface,
    required TItem Function(
      ({
        String id,
        int priority,
        Map<String, Object?> metadata,
        List<Map<String, Object?>?> options,
      }),
    )
    decodeItem,
  }) {
    final S slotSurface;
    if (json['surface'] case final String surface) {
      slotSurface = decodeSurface(surface);
    } else {
      throw ArgumentError.value(json, 'json', 'Surface is required');
    }

    ({
      String id,
      int priority,
      Map<String, Object?> metadata,
      List<Map<String, Object?>?> options,
    })
    extractItem(Map<String, Object?> item) {
      final String id;
      if (json['id'] case final String v) {
        id = v;
      } else {
        throw ArgumentError.value(json['id'], 'id', 'Expected string id');
      }

      final priority = (json['priority'] as num?)?.toInt() ?? 0;

      final Map<String, Object?> metadata;
      // ignore: strict_raw_type
      if (json['metadata'] case final Map m) {
        metadata = <String, Object?>{
          for (final e in m.entries) e.key.toString(): e.value,
        };
      } else {
        metadata = const <String, Object?>{};
      }

      final List<Map<String, Object?>?> options;
      // ignore: strict_raw_type
      if (json['options'] case final Iterable list) {
        options = <Map<String, Object?>?>[
          for (final item in list)
            if (item case <String, Object?>{
              'surface': final String surface,
              'variant': final String variant,
              'is_dismissible': final bool isDismissible,
            })
              {
                'surface': surface,
                'variant': variant,
                'is_dismissible': isDismissible,
                'stage': item['stage'] as int?,
                'max_impressions': item['max_impressions'] as int?,
                'cooldown_minutes': item['cooldown_minutes'] as int?,
                'always_on_if_eligible':
                    item['always_on_if_eligible'] as bool? ?? false,
              }
            else
              throw FormatException('Invalid item json: $item'),
        ];
      } else {
        options = const <Map<String, Object?>?>[];
      }

      return (id: id, priority: priority, metadata: metadata, options: options);
    }

    final TItem? slotActive;
    if (json['active'] case final active) {
      final $slotActive = switch (active) {
        null => null,
        Map<String, Object?> item => decodeItem(extractItem(item)),
        _ => throw FormatException('Invalid map active item: $active'),
      };
      slotActive = $slotActive;
    }

    final queueItems = <TItem>[];
    // ignore: strict_raw_type
    if (json['queue'] case Iterable queue) {
      for (final item in queue) {
        if (item case Map<String, Object?> item) {
          queueItems.add(decodeItem(extractItem(item)));
        } else {
          throw FormatException('Invalid map queue item: $item');
        }
      }
    }

    return PresentumSlot<TItem, S, V>(
      surface: slotSurface,
      active: slotActive,
      queue: queueItems,
    );
  }

  /// The surface of the slot.
  final S surface;

  /// The active item of the slot.
  final TItem? active;

  /// The queue of the slot.
  final List<TItem> queue;

  /// Serialize the slot to a JSON map.
  Map<String, Object?> toJson() => <String, Object?>{
    'surface': surface.key,
    'active': active?.option.toJson(),
    'queue': <Map<String, Object?>>[for (final q in queue) q.option.toJson()],
  };

  /// Create a copy of the slot with the given changes.
  PresentumSlot<TItem, S, V> copyWith({
    Object? active = _null,
    List<TItem>? queue,
  }) => PresentumSlot<TItem, S, V>(
    surface: surface,
    active: active == _null ? this.active : active as TItem?,
    queue: queue ?? this.queue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentumSlot<TItem, S, V> &&
        other.surface == surface &&
        other.active == active &&
        ListEquality<TItem>().equals(queue, other.queue);
  }

  @override
  int get hashCode =>
      Object.hash(surface, active, ListEquality<TItem>().hash(queue));

  @override
  String toString() =>
      'PresentumSlot(surface: $surface, active: $active, queue: $queue)';
}
