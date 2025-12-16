import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentum.dart';

/// Presentum engine.
abstract base class PresentumEngine<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// Set the candidates list.
  FutureOr<void> setCandidates(
    List<TItem> Function(
      PresentumState$Mutable<TItem, S, V> state,
      List<TItem> currentCandidates,
    )
    candidates,
  );

  /// Set the candidates list with build in diffing algorithm.
  FutureOr<void> setCandidatesWithDiff(
    List<TItem> Function(PresentumState$Mutable<TItem, S, V> state)
    newCandidates, {
    Object? Function(TItem item) getId,
    bool Function(TItem oldItem, TItem newItem)? customContentsComparison,
    void Function(int position, List<TItem> newItems)? inserted,
    void Function(int position, int count)? removed,
    void Function(int fromPosition, int toPosition)? moved,
    void Function(int position, int count, TItem? payload)? changed,
  });

  /// The current list of candidates.
  List<TItem> get currentCandidates;

  /// Set the new presentation state.
  Future<void> setNewPresentationState(PresentumState<TItem, S, V> state);

  /// The current state of the presentation engine.
  PresentumState$Immutable<TItem, S, V> get currentState;

  /// Whether the controller is currently processing a tasks.
  bool get isProcessing;

  /// Completes when processing queue is empty
  /// and all transactions are completed.
  /// This is mean controller is ready to use and in a idle state.
  Future<void> get processingCompleted;

  /// Builds a [InheritedPresentum] for a given widget [child].
  Widget build(BuildContext context, Widget child);
}
