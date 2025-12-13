import 'dart:async';

import 'package:presentum/src/state/state.dart';

/// {@template presentum_storage}
/// Storage contract used by guards (domain provides implementation).
/// {@endtemplate}
abstract interface class PresentumStorage<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// Initializes the storage.
  Future<void> init();

  /// Clears all stored data.
  Future<void> clear();

  /// Clears specific item by [itemId] on [surface] and [variant].
  FutureOr<void> clearItem(
    String itemId, {
    required S surface,
    required V variant,
  });

  /// Records when an item was shown to the user.
  FutureOr<void> recordShown(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  });

  /// Gets the last time an item was shown to the user.
  FutureOr<DateTime?> getLastShown(
    String itemId, {
    required S surface,
    required V variant,
  });

  /// Gets the number of times an item was shown within a period.
  FutureOr<int> getShownCount(
    String itemId, {
    required Duration period,
    required S surface,
    required V variant,
  });

  /// Records when an item was dismissed by the user.
  FutureOr<void> recordDismissed(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  });

  /// Gets when an item was dismissed until.
  FutureOr<DateTime?> getDismissedAt(
    String itemId, {
    required S surface,
    required V variant,
  });

  /// Records when an item led to a conversion.
  FutureOr<void> recordConverted(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  });
}

/// {@template in_memory_presentum_storage}
/// In-memory implementation of the presentum storage.
/// {@endtemplate}
class InMemoryPresentumStorage<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements PresentumStorage<S, V> {
  late Map<String, Map<String, Map<String, List<DateTime>>>> _shownStorage;
  late Map<String, Map<String, Map<String, DateTime>>> _dismissedStorage;
  late Map<String, Map<String, Map<String, List<DateTime>>>> _convertedStorage;

  @override
  Future<void> init() async {
    _shownStorage = {};
    _dismissedStorage = {};
    _convertedStorage = {};
  }

  @override
  Future<void> clear() async {
    _shownStorage.clear();
    _dismissedStorage.clear();
    _convertedStorage.clear();
  }

  @override
  FutureOr<void> clearItem(
    String itemId, {
    required S surface,
    required V variant,
  }) {
    _shownStorage.remove(itemId);
    _dismissedStorage.remove(itemId);
    _convertedStorage.remove(itemId);
  }

  @override
  FutureOr<void> recordShown(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {
    _shownStorage
        .putIfAbsent(itemId, () => {})
        .putIfAbsent(surface.name, () => {})
        .putIfAbsent(variant.name, () => [])
        .add(at);
  }

  @override
  FutureOr<DateTime?> getLastShown(
    String itemId, {
    required S surface,
    required V variant,
  }) {
    final timestamps = _shownStorage[itemId]?[surface.name]?[variant.name];
    if (timestamps == null || timestamps.isEmpty) return null;

    return timestamps.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  FutureOr<int> getShownCount(
    String itemId, {
    required Duration period,
    required S surface,
    required V variant,
  }) {
    final timestamps = _shownStorage[itemId]?[surface.name]?[variant.name];
    if (timestamps == null || timestamps.isEmpty) return 0;

    final cutoff = DateTime.now().subtract(period);
    return timestamps.where((timestamp) => !timestamp.isBefore(cutoff)).length;
  }

  @override
  FutureOr<void> recordDismissed(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {
    _dismissedStorage
            .putIfAbsent(itemId, () => {})
            .putIfAbsent(surface.name, () => {})[variant.name] =
        at;
  }

  @override
  FutureOr<DateTime?> getDismissedAt(
    String itemId, {
    required S surface,
    required V variant,
  }) => _dismissedStorage[itemId]?[surface.name]?[variant.name];

  @override
  FutureOr<void> recordConverted(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {
    _convertedStorage
        .putIfAbsent(itemId, () => {})
        .putIfAbsent(surface.name, () => {})
        .putIfAbsent(variant.name, () => [])
        .add(at);
  }
}

/// {@template no_op_presentum_storage}
/// No-op implementation of the presentum storage.
/// Used when storage is not needed.
/// {@endtemplate}
final class NoOpPresentumStorage<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements PresentumStorage<S, V> {
  /// {@macro no_op_presentum_storage}
  const NoOpPresentumStorage();

  @override
  Future<void> init() async {}

  @override
  Future<void> clear() async {}

  @override
  FutureOr<void> clearItem(
    String itemId, {
    required S surface,
    required V variant,
  }) {}

  @override
  FutureOr<void> recordShown(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {}

  @override
  FutureOr<DateTime?> getLastShown(
    String itemId, {
    required S surface,
    required V variant,
  }) => null;

  @override
  FutureOr<int> getShownCount(
    String itemId, {
    required Duration period,
    required S surface,
    required V variant,
  }) => 0;

  @override
  FutureOr<void> recordDismissed(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {}

  @override
  FutureOr<DateTime?> getDismissedAt(
    String itemId, {
    required S surface,
    required V variant,
  }) => null;

  @override
  FutureOr<void> recordConverted(
    String itemId, {
    required S surface,
    required V variant,
    required DateTime at,
  }) {}
}
