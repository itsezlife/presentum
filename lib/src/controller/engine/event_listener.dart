import 'dart:async';

import 'package:presentum/presentum.dart';
import 'package:presentum/src/controller/event_handler.dart';

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
  final PresentumStorage storage;

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
