import 'dart:async';

/// The default dismiss until date.
final dismissUntilForever = DateTime(9999, 12, 31);

/// {@template presentum_storage}
/// Storage contract used by guards (domain provides implementation).
/// {@endtemplate}
abstract interface class PresentumStorage {
  /// Initializes the storage.
  Future<void> init();

  /// Clears all stored data.
  Future<void> clear();

  /// Records when an item was shown to the user.
  FutureOr<void> recordShown(
    String itemId, {
    required Enum surface,
    required Enum variant,
    required DateTime at,
  });

  /// Gets the last time an item was shown to the user.
  FutureOr<DateTime?> getLastShown(
    String itemId, {
    required Enum surface,
    required Enum variant,
  });

  /// Gets the number of times an item was shown within a period.
  FutureOr<int> getShownCount(
    String itemId, {
    required Duration period,
    required Enum surface,
    required Enum variant,
  });

  /// Records when an item was dismissed by the user.
  FutureOr<void> recordDismissed(
    String itemId, {
    required Enum surface,
    required Enum variant,
    required DateTime until,
  });

  /// Gets when an item was dismissed until.
  FutureOr<DateTime?> getDismissedUntil(
    String itemId, {
    required Enum surface,
    required Enum variant,
  });

  /// Records when an item led to a conversion.
  FutureOr<void> recordConverted(
    String itemId, {
    required Enum surface,
    required Enum variant,
    required DateTime at,
  });
}
