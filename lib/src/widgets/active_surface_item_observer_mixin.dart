import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';

/// {@template presentum_active_surface_item_observer_mixin}
/// Observes a surface's slot for active item changes and executes custom logic.
///
/// This is a generic, reusable observer that simply tracks when the active
/// item in a slot changes and delegates the handling logic to the implementing
/// class via [onActiveItemChanged].
///
/// Use this as a base for any widget that needs to react to active item
/// changes on a specific surface.
/// {@endtemplate}
mixin PresentumActiveSurfaceItemObserverMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
  T extends StatefulWidget
>
    on State<T> {
  late final PresentumStateObserver<TItem, S, V> _observer;
  TItem? _currentActiveItem;

  /// The surface to observe for active item changes.
  PresentumSurface get surface;

  /// Whether to handle the initial active item state in [initState].
  ///
  /// If true, [onActiveItemChanged] will be called in [initState] if there's
  /// already an active item. If false, only subsequent changes trigger the
  /// callback.
  ///
  /// Default: true
  bool get handleInitialState => true;

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TItem, S, V>().observer;

    if (handleInitialState) {
      _evaluateInitialState();
    }

    _observer.addListener(_onObserverStateChange);
  }

  @override
  void dispose() {
    _observer.removeListener(_onObserverStateChange);
    super.dispose();
  }

  /// Gets the current active item from the observed slot.
  TItem? get currentActiveItem => _currentActiveItem;

  /// Gets the observer instance.
  @protected
  PresentumStateObserver<TItem, S, V> get observer => _observer;

  void _evaluateInitialState() {
    final slot = _observer.value.slots[surface];
    final initialActive = slot?.active;

    if (initialActive != null) {
      _currentActiveItem = initialActive;
      onActiveItemChanged(current: initialActive, previous: null);
    }
  }

  void _onObserverStateChange() {
    final slot = _observer.value.slots[surface];
    final newActiveItem = slot?.active;

    // Only notify if the active item actually changed
    if (newActiveItem?.id != _currentActiveItem?.id) {
      final previous = _currentActiveItem;
      _currentActiveItem = newActiveItem;
      onActiveItemChanged(current: newActiveItem, previous: previous);
    }
  }

  /// Called whenever the active item in the observed slot changes.
  ///
  /// **Parameters:**
  /// - [current]: The new active item, or null if no item is active
  /// - [previous]: The previously active item, or null if none was active
  ///
  /// **Important transitions:**
  /// - `previous: null, current: Item` → New item became active
  /// - `previous: Item, current: null` → Active item became inactive
  /// - `previous: Item1, current: Item2` → Active item was replaced
  ///
  /// Implement this to execute your custom logic in response to changes.
  void onActiveItemChanged({required TItem? current, required TItem? previous});
}
