import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:presentum/src/utils/logs.dart';

/// Strategy for handling popup conflicts when a new popup activates while
/// another is already showing.
enum PopupConflictStrategy {
  /// Ignore the new popup and keep showing the current one.
  ignore,

  /// Replace the current popup with the new one immediately.
  replace,

  /// Queue the new popup to show after the current one is dismissed.
  queue,
}

/// Result of presenting a popup.
enum PopupPresentResult {
  /// The popup was dismissed by the user (e.g., after conversion).
  /// The mixin will NOT call [markDismissed] as it's already handled.
  userDismissed,

  /// The popup was dismissed by the system or closed without user action.
  /// The mixin WILL call [markDismissed] automatically.
  systemDismissed,

  /// The popup was not presented (e.g., widget not mounted).
  /// The mixin will NOT call [markDismissed].
  notPresented,
}

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
  bool _showing = false;
  DateTime? _lastShownAt;
  final List<TItem> _queuedEntries = [];

  /// The surface to watch.
  PresentumSurface get surface;

  /// Ignore duplicate entries shown within [duplicateThreshold].
  /// Set to false to allow duplicates (default).
  bool get ignoreDuplicates => false;

  /// Time threshold for considering an entry a duplicate.
  /// Only applies when [ignoreDuplicates] is true.
  /// If null, duplicates are always ignored when [ignoreDuplicates] is true.
  Duration? get duplicateThreshold => const Duration(seconds: 3);

  /// Strategy for handling conflicts when a new popup activates while showing.
  PopupConflictStrategy get conflictStrategy => PopupConflictStrategy.ignore;

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
    _queuedEntries.clear();
    super.dispose();
  }

  void _onStateChange() {
    final state = _observer.value;
    final slot = state.slots[surface];

    /// There is an active entry, but the slot became inactive, so
    /// we need to pop the dialog and mark the entry as dismissed.
    if (_lastEntry case final entry? when _showing && slot?.active == null) {
      fine('Entry became inactive while showing: ${entry.id}');
      _dismissAndPop(entry);
      return;
    }

    /// Present the new entry if it differs from the last one.
    if (slot?.active case final entry? when entry.id != _lastEntry?.id) {
      /// Check for duplicates if enabled.
      if (ignoreDuplicates && _isDuplicate(entry)) {
        fine(
          'Ignoring duplicate entry: ${entry.id} '
          '(last shown ${DateTime.now().difference(_lastShownAt!).inSeconds}s '
          'ago)',
        );
        return;
      }

      /// Handle conflict if already showing.
      if (_showing) {
        _handleConflict(entry);
        return;
      }

      _presentEntry(entry);
    }
  }

  bool _isDuplicate(TItem entry) {
    if (_lastEntry?.id != entry.id) return false;

    final lastShown = _lastShownAt;
    if (lastShown == null) return false;

    final threshold = duplicateThreshold;
    if (threshold == null) return true; // Always duplicate if no threshold

    final elapsed = DateTime.now().difference(lastShown);
    return elapsed < threshold;
  }

  void _handleConflict(TItem entry) {
    fine(
      'Conflict: new entry ${entry.id} while showing ${_lastEntry?.id} '
      '(strategy: $conflictStrategy)',
    );

    switch (conflictStrategy) {
      case PopupConflictStrategy.ignore:
        // Do nothing, keep current popup
        break;

      case PopupConflictStrategy.replace:
        // Dismiss current and show new immediately
        if (_lastEntry case final lastEntry?) {
          _dismissAndPop(lastEntry);
        }
        _presentEntry(entry);

      case PopupConflictStrategy.queue:
        // Add to queue if not already queued
        if (!_queuedEntries.any((e) => e.id == entry.id)) {
          _queuedEntries.add(entry);
          fine(
            'Queued entry: ${entry.id} (queue size: ${_queuedEntries.length})',
          );
        }
    }
  }

  void _presentEntry(TItem entry) {
    _lastEntry = entry;
    scheduleMicrotask(() async {
      try {
        if (!mounted) return;

        _showing = true;
        _lastShownAt = DateTime.now();
        fine('Presenting entry: ${entry.id}');

        final result = await present(entry);

        fine('Entry ${entry.id} result: $result');

        // Only mark as dismissed if system dismissed it
        if (result == PopupPresentResult.systemDismissed) {
          await markDismissed(entry: entry);
        }

        _showing = false;

        // Process queue after completion
        _processQueue();
      } catch (error, stackTrace) {
        severe(error, stackTrace, 'Error presenting entry ${entry.id}');
        _showing = false;
        _processQueue(); // Try queue if presentation failed
        rethrow;
      }
    });
  }

  void _dismissAndPop(TItem entry) {
    markDismissed(entry: entry);
    pop();
    _showing = false;

    // Process queue after dismissing
    _processQueue();
  }

  void _processQueue() {
    if (_queuedEntries.isEmpty || _showing) return;

    final nextEntry = _queuedEntries.removeAt(0);
    fine(
      'Processing queued entry: ${nextEntry.id} (${_queuedEntries.length} '
      'remaining)',
    );
    _presentEntry(nextEntry);
  }

  /// Pop the current dialog/route.
  /// Override to customize pop behavior (e.g., custom navigator).
  void pop() {
    if (mounted) {
      Navigator.maybePop(context, true);
    }
  }

  /// Mark the entry as dismissed.
  /// Called when the entry is no longer active or manually dismissed.
  Future<void> markDismissed({required TItem entry});

  /// Present the entry.
  ///
  /// Returns [PopupPresentResult] indicating how the popup was dismissed:
  /// - [PopupPresentResult.userDismissed]: User explicitly dismissed it
  ///   (e.g., after conversion). The mixin will NOT call [markDismissed].
  /// - [PopupPresentResult.systemDismissed]: Dismissed by system or closed
  ///   without user action. The mixin WILL call [markDismissed] automatically.
  /// - [PopupPresentResult.notPresented]: Could not present (e.g., widget
  ///   not mounted). The mixin will NOT call [markDismissed].
  ///
  /// This typically wraps [Navigator.showDialog] and maps its result to the
  /// appropriate enum value. Check `mounted` before presenting and return
  /// [PopupPresentResult.notPresented] if not mounted.
  Future<PopupPresentResult> present(TItem entry);
}
