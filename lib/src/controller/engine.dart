import 'dart:async';

import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentation.dart';

/// Presentum engine.
abstract base class PresentumEngine<
  TResolved extends Identifiable,
  S extends PresentumSurface
> {
  /// Set the candidates list.
  FutureOr<void> setCandidates(
    List<TResolved> Function(
      PresentumState$Mutable<TResolved, S> state,
      List<TResolved> currentCandidates,
    )
    candidates,
  );

  /// The current list of candidates.
  List<TResolved> get currentCandidates;

  /// Set the new presentation state.
  Future<void> setNewPresentationState(PresentumState<TResolved, S> state);

  /// The current state of the presentation engine.
  PresentumState$Immutable<TResolved, S> get currentState;

  /// Whether the controller is currently processing a tasks.
  bool get isProcessing;

  /// Completes when processing queue is empty
  /// and all transactions are completed.
  /// This is mean controller is ready to use and in a idle state.
  Future<void> get processingCompleted;

  /// Builds a [InheritedPresentum] for a given widget [child].
  Widget build(BuildContext context, Widget child);
}
