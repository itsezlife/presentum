import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Processor for the presentum state.
typedef PresentumStateProcessor<
  TResolved extends Identifiable,
  S extends PresentumSurface
> = Future<void> Function(PresentumState<TResolved, S> state);

/// Serializes presentum state transitions.
class PresentumStateQueue<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    implements Sink<PresentumState<TResolved, S>> {
  /// {@macro presentum_state_queue}
  PresentumStateQueue({
    required PresentumStateProcessor<TResolved, S> processor,
    String debugLabel = 'PresentumStateQueue',
  }) : _stateProcessor = processor,
       _debugLabel = debugLabel;

  final DoubleLinkedQueue<_StateTask<TResolved, S>> _queue =
      DoubleLinkedQueue<_StateTask<TResolved, S>>();
  final PresentumStateProcessor<TResolved, S> _stateProcessor;
  final String _debugLabel;
  Future<void>? _processing;

  /// Completes when the queue is empty.
  Future<void> get processingCompleted => _processing ?? Future<void>.value();

  /// Notify when processing completed
  final ChangeNotifier _processingCompleteNotifier = ChangeNotifier();

  /// Add complete listener
  void addCompleteListener(VoidCallback listener) =>
      _processingCompleteNotifier.addListener(listener);

  /// Remove complete listener
  void removeCompleteListener(VoidCallback listener) =>
      _processingCompleteNotifier.removeListener(listener);

  /// Whether the queue is currently processing a task.
  bool get isProcessing => _processing != null;

  /// Whether the queue is closed.
  bool get isClosed => _closed;
  bool _closed = false;

  @override
  Future<void> add(PresentumState<TResolved, S> state) {
    if (_closed) throw StateError('StateQueue is closed');
    final task = _StateTask<TResolved, S>(state);
    _queue.add(task);
    unawaited(_start());
    developer.Timeline.instantSync('$_debugLabel:add');
    return task.future;
  }

  @override
  Future<void> close({bool force = false}) async {
    _closed = true;
    if (force) {
      for (final task in _queue) {
        task.reject(
          StateError('PresentumStateQueue is closed'),
          StackTrace.current,
        );
      }
      _queue.clear();
    } else {
      await _processing;
    }
    scheduleMicrotask(_processingCompleteNotifier.dispose);
  }

  Future<void> _start() {
    final processing = _processing;
    if (processing != null) return processing;
    final flow = developer.Flow.begin();
    developer.Timeline.instantSync('$_debugLabel:begin');
    return _processing = Future.doWhile(() async {
      if (_queue.isEmpty) {
        _processing = null;
        developer.Timeline.instantSync('$_debugLabel:end');
        developer.Flow.end(flow.id);
        return false;
      }
      try {
        await developer.Timeline.timeSync(
          '$_debugLabel:task',
          () => _queue.removeFirst()(_stateProcessor),
          flow: developer.Flow.step(flow.id),
        );
      } on Object catch (error, stackTrace) {
        developer.log(
          'Failed to process state',
          name: 'presentum',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
      }
      return true;
    });
  }
}

@immutable
class _StateTask<TResolved extends Identifiable, S extends PresentumSurface> {
  _StateTask(PresentumState<TResolved, S> state)
    : _state = state,
      _completer = Completer<void>.sync();

  final PresentumState<TResolved, S> _state;
  final Completer<void> _completer;

  Future<void> get future => _completer.future;

  Future<void> call(
    Future<void> Function(PresentumState<TResolved, S>) fn,
  ) async {
    try {
      if (_completer.isCompleted) return;
      await fn(_state);
      if (_completer.isCompleted) return;
      _completer.complete();
    } on Object catch (error, stackTrace) {
      _completer.completeError(error, stackTrace);
    }
  }

  void reject(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return; // coverage:ignore-line
    _completer.completeError(error, stackTrace);
  }
}
