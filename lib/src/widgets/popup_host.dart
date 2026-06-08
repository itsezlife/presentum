import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/utils/logs.dart';

/// Strategy for handling popup conflicts when a new popup activates while
/// another is already showing.
enum PopupConflictStrategy {
  /// Ignore the new popup and keep showing the current one.
  ignore,

  /// Replace the current popup with the new one immediately.
  replace,

  /// Defer presenting until the current dialog closes (slot queue is truth).
  queue,
}

/// Result of presenting a popup.
enum PopupPresentResult {
  /// User dismissed in UI — host already updated slots/storage.
  userDismissed,

  /// System dismissed — [PresentumPopupHost.onMarkDismissed] runs.
  systemDismissed,

  /// Popup was not presented (e.g. widget unmounted).
  notPresented,
}

/// {@template presentum_popup_host}
/// Presents popup-surface actives from [slots] — no engine dependency.
/// {@endtemplate}
class PresentumPopupHost<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_popup_host}
  const PresentumPopupHost({
    required this.slots,
    required this.surface,
    required this.present,
    required this.child,
    this.onShown,
    this.onMarkDismissed,
    this.ignoreDuplicates = false,
    this.duplicateThreshold = const Duration(seconds: 3),
    this.conflictStrategy = PopupConflictStrategy.ignore,
    super.key,
  });

  /// Slot state — active + queue are the single source of truth.
  final PresentumSlotState<TItem, S, V> slots;

  /// Popup surface to watch.
  final S surface;

  /// Shows the dialog or fullscreen promo for [item].
  final Future<PopupPresentResult> Function(TItem item) present;

  /// Called before [present] (impression before dialog).
  final FutureOr<void> Function(TItem item)? onShown;

  /// Called when [PopupPresentResult.systemDismissed] — wire to lifecycle.
  final FutureOr<void> Function(TItem item)? onMarkDismissed;

  /// Ignore duplicate actives within [duplicateThreshold].
  final bool ignoreDuplicates;

  /// Duplicate window when [ignoreDuplicates] is true.
  final Duration? duplicateThreshold;

  /// Behavior when active changes while a dialog is on screen.
  final PopupConflictStrategy conflictStrategy;

  /// Subtree below this host.
  final Widget child;

  @override
  State<PresentumPopupHost<TItem, S, V>> createState() =>
      _PresentumPopupHostState<TItem, S, V>();
}

class _PresentumPopupHostState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumPopupHost<TItem, S, V>> {
  bool _showing = false;
  TItem? _trackedActive;
  TItem? _lastShownEntry;
  DateTime? _lastShownAt;
  TItem? _pendingItem;

  @override
  void initState() {
    super.initState();
    _trackedActive = widget.slots.activeFor(widget.surface);
    if (_trackedActive != null) {
      _onActiveChanged(previous: null, current: _trackedActive);
    }
  }

  @override
  void didUpdateWidget(PresentumPopupHost<TItem, S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots == oldWidget.slots) return;

    final previous = _trackedActive;
    final current = widget.slots.activeFor(widget.surface);
    if (previous?.id == current?.id) return;

    _trackedActive = current;
    _onActiveChanged(previous: previous, current: current);
  }

  void _onActiveChanged({required TItem? previous, required TItem? current}) {
    if (previous != null && current == null && _showing) {
      fine('Entry ${previous.id} became inactive while showing');
      unawaited(_dismissAndPop(previous));
      return;
    }

    if (current == null) return;

    if (widget.ignoreDuplicates && _isDuplicate(current)) {
      fine('Ignoring duplicate entry: ${current.id}');
      return;
    }

    if (_showing) {
      _handleConflict(current);
      return;
    }

    unawaited(_presentEntry(current));
  }

  bool _isDuplicate(TItem entry) {
    if (_lastShownEntry?.id != entry.id) return false;

    final lastShown = _lastShownAt;
    if (lastShown == null) return false;

    final threshold = widget.duplicateThreshold;
    if (threshold == null) return true;

    return DateTime.now().difference(lastShown) < threshold;
  }

  void _handleConflict(TItem entry) {
    fine(
      'Conflict: new entry ${entry.id} while showing '
      '(strategy: ${widget.conflictStrategy})',
    );

    switch (widget.conflictStrategy) {
      case PopupConflictStrategy.ignore:
        break;
      case PopupConflictStrategy.replace:
        if (_lastShownEntry case final showing?) {
          unawaited(_dismissAndPop(showing));
        }
        unawaited(_presentEntry(entry));
      case PopupConflictStrategy.queue:
        _pendingItem = entry;
        fine('Deferred present pending: ${entry.id}');
    }
  }

  Future<void> _presentEntry(TItem entry) async {
    _lastShownEntry = entry;

    try {
      if (!mounted) return;

      _showing = true;
      _lastShownAt = DateTime.now();
      fine('Presenting entry: ${entry.id}');

      await widget.onShown?.call(entry);
      if (!mounted) {
        _showing = false;
        return;
      }

      final result = await widget.present(entry);
      fine('Entry ${entry.id} result: $result');

      if (result == PopupPresentResult.systemDismissed) {
        await widget.onMarkDismissed?.call(entry);
      }
    } on Object catch (error, stackTrace) {
      severe(error, stackTrace, 'Error presenting entry ${entry.id}');
      rethrow;
    } finally {
      _showing = false;
      await _presentPendingIfNeeded();
    }
  }

  Future<void> _dismissAndPop(TItem entry) async {
    await widget.onMarkDismissed?.call(entry);
    _pop();
    _showing = false;
    await _presentPendingIfNeeded();
  }

  Future<void> _presentPendingIfNeeded() async {
    if (_showing) return;

    final pending = _pendingItem;
    if (pending == null) return;

    _pendingItem = null;
    final active = widget.slots.activeFor(widget.surface);
    if (active?.id == pending.id) {
      unawaited(_presentEntry(pending));
    }
  }

  void _pop() {
    if (mounted) {
      Navigator.maybePop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
