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
/// Manages popup presentation (dialogs/fullscreen widgets) for a surface.
///
/// Internally uses [PresentumActiveSurfaceItemObserverMixin] to observe active
/// items and adds popup-specific behavior: duplicate detection, conflict
/// resolution, and queuing.
/// {@endtemplate}
mixin PresentumPopupSurfaceStateMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
  T extends StatefulWidget
>
    on State<T>, PresentumActiveSurfaceItemObserverMixin<TItem, S, V, T> {
  bool _showing = false;
  TItem? _lastShownEntry;
  DateTime? _lastShownAt;
  final List<TItem> _queuedEntries = [];

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
  bool get handleInitialState => true;

  @override
  void dispose() {
    _queuedEntries.clear();
    super.dispose();
  }

  @override
  void onActiveItemChanged({
    required TItem? current,
    required TItem? previous,
  }) {
    // Case 1: Active item became inactive while we're showing it
    if (previous case final previous? when current == null && _showing) {
      fine('Entry ${previous.id} became inactive while showing');
      _dismissAndPop(previous);
      return;
    }

    // Case 2: New item became active
    if (current != null) {
      // Check for duplicates if enabled
      if (ignoreDuplicates && _isDuplicate(current)) {
        fine(
          'Ignoring duplicate entry: ${current.id} '
          '(last shown ${DateTime.now().difference(_lastShownAt!).inSeconds}s '
          'ago)',
        );
        return;
      }

      // Handle conflict if already showing
      if (_showing) {
        _handleConflict(current);
        return;
      }

      _presentEntry(current);
    }
  }

  bool _isDuplicate(TItem entry) {
    if (_lastShownEntry?.id != entry.id) return false;

    final lastShown = _lastShownAt;
    if (lastShown == null) return false;

    final threshold = duplicateThreshold;
    if (threshold == null) return true; // Always duplicate if no threshold

    final elapsed = DateTime.now().difference(lastShown);
    return elapsed < threshold;
  }

  void _handleConflict(TItem entry) {
    final currentEntry = currentActiveItem;
    fine(
      'Conflict: new entry ${entry.id} while showing ${currentEntry?.id} '
      '(strategy: $conflictStrategy)',
    );

    switch (conflictStrategy) {
      case PopupConflictStrategy.ignore:
        // Do nothing, keep current popup
        break;

      case PopupConflictStrategy.replace:
        // Dismiss current and show new immediately
        if (currentEntry != null) {
          _dismissAndPop(currentEntry);
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
    _lastShownEntry = entry;
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
  Future<void> markDismissed({required TItem entry}) =>
      context.presentum<TItem, S, V>().markDismissed(entry);

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
