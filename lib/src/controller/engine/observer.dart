import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

@internal
final class PresentumStateObserver$EngineImpl<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    with ChangeNotifier
    implements PresentumStateObserver<TResolved, S, V> {
  PresentumStateObserver$EngineImpl(
    PresentumState$Immutable<TResolved, S, V> initialState, [
    List<PresentumHistoryEntry<TResolved, S, V>>? history,
  ]) : _value = initialState.copy(),
       _history =
           history?.toSet().toList() ??
           <PresentumHistoryEntry<TResolved, S, V>>[] {
    if (_history.isEmpty || _history.last.state != initialState) {
      _history.add(
        PresentumHistoryEntry<TResolved, S, V>(
          state: initialState,
          timestamp: DateTime.now(),
        ),
      );
    }
    _history.sort();
  }

  late PresentumState$Immutable<TResolved, S, V> _value;

  final List<PresentumHistoryEntry<TResolved, S, V>> _history;

  @override
  PresentumState$Immutable<TResolved, S, V> get value => _value;

  @override
  List<PresentumHistoryEntry<TResolved, S, V>> get history =>
      UnmodifiableListView<PresentumHistoryEntry<TResolved, S, V>>(_history);

  @override
  void setHistory(Iterable<PresentumHistoryEntry<TResolved, S, V>> history) {
    _history
      ..clear()
      ..addAll(history)
      ..sort();
  }

  @internal
  bool changeState(PresentumState$Immutable<TResolved, S, V> state) {
    if (state.slots.isEmpty) return false;
    if (state.intention == PresentumStateIntention.cancel) return false;

    if (_value == state) return false;
    _value = state;

    late final historyEntry = PresentumHistoryEntry<TResolved, S, V>(
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
