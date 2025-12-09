import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

@internal
final class PresentumStateObserver$EngineImpl<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    with ChangeNotifier
    implements PresentumStateObserver<TResolved, S> {
  PresentumStateObserver$EngineImpl(
    PresentumState$Immutable<TResolved, S> initialState, [
    List<PresentumHistoryEntry<TResolved, S>>? history,
  ]) : _value = initialState.copy(),
       _history =
           history?.toSet().toList() ??
           <PresentumHistoryEntry<TResolved, S>>[] {
    if (_history.isEmpty || _history.last.state != initialState) {
      _history.add(
        PresentumHistoryEntry<TResolved, S>(
          state: initialState,
          timestamp: DateTime.now(),
        ),
      );
    }
    _history.sort();
  }

  late PresentumState$Immutable<TResolved, S> _value;

  final List<PresentumHistoryEntry<TResolved, S>> _history;

  @override
  PresentumState$Immutable<TResolved, S> get value => _value;

  @override
  List<PresentumHistoryEntry<TResolved, S>> get history =>
      UnmodifiableListView<PresentumHistoryEntry<TResolved, S>>(_history);

  @override
  void setHistory(Iterable<PresentumHistoryEntry<TResolved, S>> history) {
    _history
      ..clear()
      ..addAll(history)
      ..sort();
  }

  @internal
  bool changeState(PresentumState$Immutable<TResolved, S> state) {
    if (state.slots.isEmpty) return false;
    if (state.intention == PresentumStateIntention.cancel) return false;

    if (_value == state) return false;
    _value = state;

    late final historyEntry = PresentumHistoryEntry<TResolved, S>(
      state: state,
      timestamp: DateTime.now(),
    );

    switch (state.intention) {
      case PresentumStateIntention.auto:
      case PresentumStateIntention.append:
      case PresentumStateIntention.replace when _history.isEmpty:
        _history.add(historyEntry);
      case PresentumStateIntention.replace:
        _history.last = historyEntry;
      case PresentumStateIntention.cancel:
        break;
    }

    if (_history.length > PresentumStateObserver.maxHistoryLength) {
      _history.removeAt(0);
    }
    notifyListeners();
    return true;
  }
}
