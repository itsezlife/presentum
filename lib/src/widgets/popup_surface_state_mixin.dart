import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';

/// {@template presentum_popup_surface_state_mixin}
/// Watches the popup surface and presents dialogs/fullscreen widgets.
/// {@endtemplate}
mixin PresentumPopupSurfaceStateMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
  T extends StatefulWidget
>
    on State<T> {
  late final PresentumStateObserver<TItem, S, V> _observer;
  TItem? _lastEntry;

  final bool _showing = false;

  /// The surface to watch.
  PresentumSurface get surface;

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TItem, S, V>().observer;

    /// Handle initial state evaluation.
    _onStateChange();

    _observer.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _observer.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    final state = _observer.value;
    final slot = state.slots[surface];

    /// There is an active entry, but the slot become inactive, so
    /// we need to pop the dialog and mark the entry as dismissed.
    if (_lastEntry case final entry? when _showing && slot?.active == null) {
      markDismissed(entry: entry, pop: true);
      return;
    }

    /// Present the new entry if it is not the same as the last one and the
    /// previous one is not showing.
    if (slot?.active case final entry?
        when entry.id != _lastEntry?.id && !_showing) {
      _lastEntry = entry;
      scheduleMicrotask(() => present(entry));
    }
  }

  /// Mark the entry as dismissed.
  Future<void> markDismissed({required TItem entry, bool pop = false});

  /// Present the entry.
  Future<void> present(TItem entry);
}
