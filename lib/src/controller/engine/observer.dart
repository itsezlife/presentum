import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

@internal
final class PresentumStateObserver$EngineImpl<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    with ChangeNotifier
    implements PresentumStateObserver<TItem, S, V> {
  PresentumStateObserver$EngineImpl(
    PresentumState$Immutable<TItem, S, V> initialState, [
    List<PresentumHistoryEntry<TItem, S, V>>? history,
  ]) : _value = initialState.copy(),
       _history =
           history?.toSet().toList() ?? <PresentumHistoryEntry<TItem, S, V>>[] {
    if (_history.isEmpty || _history.last.state != initialState) {
      _history.add(
        PresentumHistoryEntry<TItem, S, V>(
          state: initialState,
          timestamp: DateTime.now(),
        ),
      );
    }
    _history.sort();
  }

  late PresentumState$Immutable<TItem, S, V> _value;

  final List<PresentumHistoryEntry<TItem, S, V>> _history;

  @override
  PresentumState$Immutable<TItem, S, V> get value => _value;

  @override
  List<PresentumHistoryEntry<TItem, S, V>> get history =>
      UnmodifiableListView<PresentumHistoryEntry<TItem, S, V>>(_history);

  @override
  void setHistory(Iterable<PresentumHistoryEntry<TItem, S, V>> history) {
    _history
      ..clear()
      ..addAll(history)
      ..sort();
  }

  @internal
  bool changeState(PresentumState$Immutable<TItem, S, V> state) {
    if (state.intention == PresentumStateIntention.cancel) return false;

    if (_value == state) return false;
    _value = state;

    late final historyEntry = PresentumHistoryEntry<TItem, S, V>(
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
