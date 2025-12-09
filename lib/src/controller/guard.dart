// ignore_for_file: comment_references, document_ignores

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Guard for the presentum.
///
/// {@template guard}
/// This is good place for checking eligibility, authentication, subscription
/// plan, A/B testing, feature flags, etc.
///
/// If the guard throws an error,
/// the presentum will not change the state at all.
///
/// You should return the same state if you don't want to change it.
///
/// You should return the new state if you want to change it.
///
/// If something changed in app state, you should notify the guard
/// and presentum rerun the all guards with current state.
/// {@endtemplate}
abstract interface class IPresentumGuard<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    implements Listenable {
  /// Called when the [PresentumState] changes.
  ///
  /// [storage] is the storage of the [ResolvedPresentumVariant]s.
  /// [history] is the history of the [PresentumHistoryEntry] states.
  /// [state] is the current state of the presentum.
  /// [candidates] is the list of presentum resolved items from providers.
  /// [context] allow pass data between guards.
  ///
  /// Return the new state or [state] to update the presentation
  /// slots with new active/queued resolved presentation variants.
  ///
  /// Set `state.intention` to [PresentumStateIntention.cancel]
  /// for cancel state transition.
  ///
  /// DO NOT USE [notifyListeners] IN THIS METHOD TO AVOID INFINITE LOOP!
  ///
  /// {@macro guard}
  FutureOr<PresentumState<TResolved, S>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<TResolved, S>> history,
    PresentumState$Mutable<TResolved, S> state,
    List<TResolved> candidates,
    Map<String, Object?> context,
  );
}

/// Guard for the router.
///
/// [refresh] is the [Listenable] to listen to changes and rerun the guard.
///
/// {@macro guard}
abstract class PresentumGuard<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    with ChangeNotifier
    implements IPresentumGuard<TResolved, S> {
  /// {@macro guard}
  PresentumGuard({Listenable? refresh}) : _refresh = refresh {
    _refresh?.addListener(notifyListeners);
  }

  final Listenable? _refresh;

  @override
  FutureOr<PresentumState<TResolved, S>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<TResolved, S>> history,
    PresentumState$Mutable<TResolved, S> state,
    List<TResolved> candidates,
    Map<String, Object?> context,
  ) => state;

  @override
  void dispose() {
    _refresh?.removeListener(notifyListeners);
    super.dispose();
  }
}
