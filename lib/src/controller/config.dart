import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/controller/engine.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_config}
/// Creates a Presentum configuration.
/// {@endtemplate}
class PresentumConfig<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_config}
  PresentumConfig({
    required this.storage,
    required this.observer,
    required this.engine,
  });

  /// The [PresentumStorage] that is used to store the presentation data:
  /// - shown items
  /// - dismissed items
  /// - converted items
  /// - cooldown periods
  /// - etc.
  final PresentumStorage<S, V> storage;

  /// The [PresentumStateObserver] that is used to observe the [Presentum]
  /// state.
  final PresentumStateObserver<TResolved, S, V> observer;

  /// The [PresentumEngine] that is used to manage the [Presentum] state.
  final PresentumEngine<TResolved, S, V> engine;
}
