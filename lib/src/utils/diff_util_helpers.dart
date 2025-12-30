/// Helper classes and utilities for DiffUtil

library;

import 'package:flutter/foundation.dart';
import 'package:presentum/src/utils/diff_util.dart';

/// A simple implementation of [DiffCallback] for comparing two lists directly.
class ListDiffCallback<T> extends DiffCallback {
  /// Creates a new [ListDiffCallback] instance.
  const ListDiffCallback({
    required this.oldList,
    required this.newList,
    required this.itemCallback,
  });

  /// The old list.
  final List<T> oldList;

  /// The new list.
  final List<T> newList;

  /// The item callback.
  final ItemCallback<T> itemCallback;

  @override
  int get oldListSize => oldList.length;

  @override
  int get newListSize => newList.length;

  @override
  bool areItemsTheSame(int oldItemPosition, int newItemPosition) => itemCallback
      .areItemsTheSame(oldList[oldItemPosition], newList[newItemPosition]);

  @override
  bool areContentsTheSame(int oldItemPosition, int newItemPosition) =>
      itemCallback.areContentsTheSame(
        oldList[oldItemPosition],
        newList[newItemPosition],
      );

  @override
  Object? getChangePayload(int oldItemPosition, int newItemPosition) =>
      itemCallback.getChangePayload(
        oldList[oldItemPosition],
        newList[newItemPosition],
      );
}

/// A simple [ItemCallback] implementation that uses object equality and a
/// custom ID function.
class SimpleItemCallback<T> extends ItemCallback<T> {
  /// Creates a new [SimpleItemCallback] instance.
  const SimpleItemCallback({
    required this.getId,
    this.customContentsComparison,
  });

  /// The function to get the ID from the item.
  final Object? Function(T item) getId;

  /// The custom contents comparison function.
  final bool Function(T oldItem, T newItem)? customContentsComparison;

  @override
  bool areItemsTheSame(T oldItem, T newItem) =>
      getId(oldItem) == getId(newItem);

  @override
  bool areContentsTheSame(T oldItem, T newItem) {
    if (customContentsComparison case final comparison?) {
      return comparison(oldItem, newItem);
    }
    return oldItem == newItem;
  }

  @override
  Object? getChangePayload(T oldItem, T newItem) => newItem;
}

/// A [ListUpdateCallback] that collects all operations into lists for later
/// processing.
class CollectingListUpdateCallback implements ListUpdateCallback {
  /// {@macro collecting_list_update_callback}
  CollectingListUpdateCallback({
    this.inserted,
    this.removed,
    this.moved,
    this.changed,
  });

  /// The function to call when items have been inserted into the list.
  final void Function(int position, int count)? inserted;

  /// The function to call when items have been removed from the list.
  final void Function(int position, int count)? removed;

  /// The function to call when an item has moved from one position to another.
  final void Function(int fromPosition, int toPosition)? moved;

  /// The function to call when an item has changed.
  final void Function(int position, int count, Object? payload)? changed;

  /// The list of insert operations.
  final List<InsertOperation> insertions = [];

  /// The list of remove operations.
  final List<RemoveOperation> removals = [];

  /// The list of move operations.
  final List<MoveOperation> moves = [];

  /// The list of change operations.
  final List<ChangeOperation> changes = [];

  @override
  void onInserted(int position, int count) {
    insertions.add(InsertOperation(position, count));
    inserted?.call(position, count);
  }

  @override
  void onRemoved(int position, int count) {
    removals.add(RemoveOperation(position, count));
    removed?.call(position, count);
  }

  @override
  void onMoved(int fromPosition, int toPosition) {
    moves.add(MoveOperation(fromPosition, toPosition));
    moved?.call(fromPosition, toPosition);
  }

  @override
  void onChanged(int position, int count, [Object? payload]) {
    changes.add(ChangeOperation(position, count, payload));
    changed?.call(position, count, payload);
  }

  /// Clears all collected operations.
  void clear() {
    insertions.clear();
    removals.clear();
    moves.clear();
    changes.clear();
  }

  /// Returns true if no operations were collected.
  bool get isEmpty =>
      insertions.isEmpty &&
      removals.isEmpty &&
      moves.isEmpty &&
      changes.isEmpty;

  /// Returns the total number of operations collected.
  int get totalOperations =>
      insertions.length + removals.length + moves.length + changes.length;

  @override
  String toString() =>
      'CollectingListUpdateCallback(insertions: $insertions, removals: '
      '$removals, moves: $moves, changes: $changes, '
      'totalOperations: $totalOperations)';
}

/// Represents an insert operation.
@immutable
class InsertOperation {
  /// {@macro insert_operation}
  const InsertOperation(this.position, this.count);

  /// The position of the insert operation.
  final int position;

  /// The count of the insert operation.
  final int count;

  @override
  String toString() => 'Insert($position, $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertOperation &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          count == other.count;

  @override
  int get hashCode => position.hashCode ^ count.hashCode;
}

/// Represents a remove operation.
@immutable
class RemoveOperation {
  /// {@macro remove_operation}
  const RemoveOperation(this.position, this.count);

  /// The position of the remove operation.
  final int position;

  /// The count of the remove operation.
  final int count;

  @override
  String toString() => 'Remove($position, $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoveOperation &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          count == other.count;

  @override
  int get hashCode => position.hashCode ^ count.hashCode;
}

/// Represents a move operation.
@immutable
class MoveOperation {
  /// {@macro move_operation}
  const MoveOperation(this.fromPosition, this.toPosition);

  /// The from position of the move operation.
  final int fromPosition;

  /// The to position of the move operation.
  final int toPosition;

  @override
  String toString() => 'Move($fromPosition -> $toPosition)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveOperation &&
          runtimeType == other.runtimeType &&
          fromPosition == other.fromPosition &&
          toPosition == other.toPosition;

  @override
  int get hashCode => fromPosition.hashCode ^ toPosition.hashCode;
}

/// Represents a change operation.
@immutable
class ChangeOperation {
  /// {@macro change_operation}
  const ChangeOperation(this.position, this.count, [this.payload]);

  /// The position of the change operation.
  final int position;

  /// The count of the change operation.
  final int count;

  /// The payload of the change operation.
  final Object? payload;

  @override
  String toString() =>
      'Change($position, $count${payload != null ? ', $payload' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeOperation &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          count == other.count &&
          payload == other.payload;

  @override
  int get hashCode => position.hashCode ^ count.hashCode ^ payload.hashCode;
}

/// Utility class with convenience methods for common DiffUtil operations.
class DiffUtils {
  DiffUtils._();

  /// Calculates diff between two lists using a simple ID-based comparison.
  ///
  /// [oldList] The original list
  /// [newList] The new list
  /// [getId] Function to extract unique ID from each item
  /// [detectMoves] Whether to detect move operations (default: true)
  /// [customContentsComparison] Optional custom function to compare item
  /// contents
  ///
  /// Returns a [DiffResult] containing the differences.
  static DiffResult calculateListDiff<T>(
    List<T> oldList,
    List<T> newList,
    Object? Function(T item) getId, {
    bool detectMoves = true,
    bool Function(T oldItem, T newItem)? customContentsComparison,
  }) {
    final itemCallback = SimpleItemCallback<T>(
      getId: getId,
      customContentsComparison: customContentsComparison,
    );

    final callback = ListDiffCallback<T>(
      oldList: oldList,
      newList: newList,
      itemCallback: itemCallback,
    );

    return DiffUtil.calculateDiffWithMoves(callback, detectMoves: detectMoves);
  }

  /// Calculates diff and returns all operations as a convenient collection.
  ///
  /// [oldList] The original list
  /// [newList] The new list
  /// [getId] Function to extract unique ID from each item
  /// [detectMoves] Whether to detect move operations (default: true)
  /// [customContentsComparison] Optional custom function to compare item
  /// contents
  ///
  /// Returns a [CollectingListUpdateCallback] with all operations.
  static CollectingListUpdateCallback calculateListDiffOperations<T>(
    List<T> oldList,
    List<T> newList,
    Object? Function(T item) getId, {
    bool detectMoves = true,
    bool Function(T oldItem, T newItem)? customContentsComparison,
    void Function(int position, int count)? inserted,
    void Function(int position, int count)? removed,
    void Function(int fromPosition, int toPosition)? moved,
    void Function(int position, int count, Object? payload)? changed,
  }) {
    final diffResult = calculateListDiff<T>(
      oldList,
      newList,
      getId,
      detectMoves: detectMoves,
      customContentsComparison: customContentsComparison,
    );

    final collector = CollectingListUpdateCallback(
      inserted: inserted,
      removed: removed,
      moved: moved,
      changed: changed,
    );
    diffResult.dispatchUpdatesTo(collector);
    return collector;
  }
}
