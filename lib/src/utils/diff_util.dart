/// Dart equivalent of Android's DiffUtil
///
/// DiffUtil is a utility class that calculates the difference between two lists
/// and outputs a list of update operations that converts the first list into
/// the second one.
///
/// It uses Eugene W. Myers's difference algorithm to calculate the minimal
/// number of updates to convert one list into another. Myers's algorithm does
/// not handle items that are moved so DiffUtil runs a second pass on the
/// result to detect items that were moved.
///
/// Note that DiffUtil requires the list to not mutate while in use.
/// This generally means that both the lists themselves and their elements (or
/// at least, the properties of elements used in diffing) should not be
/// modified  directly. Instead, new lists should be provided any time
/// content changes.
///
/// If the lists are large, this operation may take significant time so you are
/// advised to run this on a background isolate, get the [DiffResult] then
/// apply it on the main isolate.
///
/// This algorithm is optimized for space and uses O(N) space to find the
/// minimal number of addition and removal operations between the two lists.
/// It has O(N + D^2) expected time performance where D is the length of the
/// edit script.
///
/// If move detection is enabled, it takes an additional O(N^2) time where N is
/// the total number of
/// added and removed items. If your lists are already sorted by the same
/// constraint (e.g. a created timestamp for a list of posts), you can disable
/// move detection to improve performance.
///
/// Due to implementation constraints, the max size of the list can be 2^26.

library;

import 'dart:math' as math;

/// Abstract callback class used by DiffUtil while calculating the diff between
/// two lists.
abstract class DiffCallback {
  /// {@macro diff_callback}
  const DiffCallback();

  /// Returns the size of the old list.
  int get oldListSize;

  /// Returns the size of the new list.
  int get newListSize;

  /// Called by the DiffUtil to decide whether two objects represent the same
  /// Item.
  ///
  /// For example, if your items have unique ids, this method should check
  /// their id equality.
  ///
  /// [oldItemPosition] The position of the item in the old list
  /// [newItemPosition] The position of the item in the new list
  /// Returns true if the two items represent the same object or false if they
  /// are different.
  bool areItemsTheSame(int oldItemPosition, int newItemPosition);

  /// Called by the DiffUtil when it wants to check whether two items have the
  /// same data.
  /// DiffUtil uses this information to detect if the contents of an item has
  /// changed.
  ///
  /// DiffUtil uses this method to check equality instead of [Object.operator==]
  /// so that you can change its behavior depending on your UI.
  ///
  /// This method is called only if [areItemsTheSame] returns true for these
  /// items.
  ///
  /// [oldItemPosition] The position of the item in the old list
  /// [newItemPosition] The position of the item in the new list which replaces
  /// the oldItem
  /// Returns true if the contents of the items are the same or false if they
  /// are different.
  bool areContentsTheSame(int oldItemPosition, int newItemPosition);

  /// When [areItemsTheSame] returns true for two items and
  /// [areContentsTheSame] returns false for them, DiffUtil
  /// calls this method to get a payload about the change.
  ///
  /// Default implementation returns null.
  ///
  /// [oldItemPosition] The position of the item in the old list
  /// [newItemPosition] The position of the item in the new list
  ///
  /// Returns a payload object that represents the change between the two items.
  Object? getChangePayload(int oldItemPosition, int newItemPosition) => null;
}

/// Callback for calculating the diff between two non-null items in a list.
///
/// [DiffCallback] serves two roles - list indexing, and item diffing.
/// ItemCallback handles just the second of these, which allows separation of
/// code that indexes into an array or List from the presentation-layer and
/// content specific diffing code.
abstract class ItemCallback<T> {
  /// Creates a new [ItemCallback] instance.
  const ItemCallback();

  /// Called to check whether two objects represent the same item.
  ///
  /// For example, if your items have unique ids, this method should check
  /// their id equality.
  ///
  /// Note: null items in the list are assumed to be the same as another null
  /// item and are assumed to not be the same as a non-null item. This callback
  /// will not be invoked for either of those cases.
  ///
  /// [oldItem] The item in the old list.
  /// [newItem] The item in the new list.
  /// Returns true if the two items represent the same object or false if they
  /// are different.
  bool areItemsTheSame(T oldItem, T newItem);

  /// Called to check whether two items have the same data.
  ///
  /// This information is used to detect if the contents of an item have
  /// changed.
  ///
  /// This method to check equality instead of [Object.operator==] so that you
  /// can change its behavior depending on your UI.
  ///
  /// This method is called only if [areItemsTheSame] returns true for
  /// these items.
  ///
  /// Note: Two null items are assumed to represent the same contents. This
  /// callback will not be invoked for this case.
  ///
  /// [oldItem] The item in the old list.
  /// [newItem] The item in the new list.
  /// Returns true if the contents of the items are the same or false if they
  /// are different.
  bool areContentsTheSame(T oldItem, T newItem);

  /// When [areItemsTheSame] returns true for two items and
  /// [areContentsTheSame] returns false for them, this method is called to
  /// get a payload about the change.
  ///
  /// Default implementation returns null.
  Object? getChangePayload(T oldItem, T newItem) => null;
}

/// Interface for receiving update operations from DiffResult.
abstract class ListUpdateCallback {
  /// {@macro list_update_callback}
  const ListUpdateCallback();

  /// Called when items have been inserted into the list.
  ///
  /// [position] The position where items were inserted
  /// [count] The number of items that were inserted
  void onInserted(int position, int count);

  /// Called when items have been removed from the list.
  ///
  /// [position] The position where items were removed
  /// [count] The number of items that were removed
  void onRemoved(int position, int count);

  /// Called when an item has moved from one position to another.
  ///
  /// [fromPosition] The original position of the item
  /// [toPosition] The new position of the item
  void onMoved(int fromPosition, int toPosition);

  /// Called when an item has changed.
  ///
  /// [position] The position of the item that changed
  /// [count] The number of items that changed (usually 1)
  /// [payload] Optional payload object representing the change
  void onChanged(int position, int count, [Object? payload]);
}

/// A batching implementation of [ListUpdateCallback] that can batch consecutive
/// operations of the same type.
class BatchingListUpdateCallback implements ListUpdateCallback {
  /// {@macro batching_list_update_callback}
  BatchingListUpdateCallback(this._wrapped);

  /// The wrapped list update callback.
  final ListUpdateCallback _wrapped;

  int _lastEventType = _typeNone;
  int _lastEventPosition = -1;
  int _lastEventCount = -1;
  Object? _lastEventPayload;

  static const int _typeNone = 0;
  static const int _typeAdd = 1;
  static const int _typeRemove = 2;
  static const int _typeChange = 3;

  /// Dispatches any pending batched events.
  void dispatchLastEvent() {
    if (_lastEventType == _typeNone) {
      return;
    }
    switch (_lastEventType) {
      case _typeAdd:
        _wrapped.onInserted(_lastEventPosition, _lastEventCount);
      case _typeRemove:
        _wrapped.onRemoved(_lastEventPosition, _lastEventCount);
      case _typeChange:
        _wrapped.onChanged(
          _lastEventPosition,
          _lastEventCount,
          _lastEventPayload,
        );
    }
    _lastEventPayload = null;
    _lastEventType = _typeNone;
  }

  @override
  void onInserted(int position, int count) {
    if (_lastEventType == _typeAdd &&
        position >= _lastEventPosition &&
        position <= _lastEventPosition + _lastEventCount) {
      _lastEventCount += count;
      return;
    }
    dispatchLastEvent();
    _lastEventPosition = position;
    _lastEventCount = count;
    _lastEventType = _typeAdd;
  }

  @override
  void onRemoved(int position, int count) {
    if (_lastEventType == _typeRemove &&
        _lastEventPosition >= position &&
        _lastEventPosition <= position + count) {
      _lastEventCount += count;
      _lastEventPosition = position;
      return;
    }
    dispatchLastEvent();
    _lastEventPosition = position;
    _lastEventCount = count;
    _lastEventType = _typeRemove;
  }

  @override
  void onMoved(int fromPosition, int toPosition) {
    dispatchLastEvent();
    _wrapped.onMoved(fromPosition, toPosition);
  }

  @override
  void onChanged(int position, int count, [Object? payload]) {
    if (_lastEventType == _typeChange &&
        !(position > _lastEventPosition + _lastEventCount ||
            position + count < _lastEventPosition ||
            _lastEventPayload != payload)) {
      // merge
      final previousEnd = _lastEventPosition + _lastEventCount;
      _lastEventPosition = math.min(position, _lastEventPosition);
      _lastEventCount =
          math.max(previousEnd, position + count) - _lastEventPosition;
      return;
    }
    dispatchLastEvent();
    _lastEventPosition = position;
    _lastEventCount = count;
    _lastEventPayload = payload;
    _lastEventType = _typeChange;
  }
}

/// Snakes represent a match between two lists. It is optionally prefixed or
/// postfixed with an add or remove operation. See the Myers' paper for details.
class _Snake {
  /// Position in the old list
  int x = 0;

  /// Position in the new list
  int y = 0;

  /// Number of matches. Might be 0.
  int size = 0;

  /// If true, this is a removal from the original list followed by [size]
  /// matches.
  /// If false, this is an addition from the new list followed by [size]
  /// matches.
  bool removal = false;

  /// If true, the addition or removal is at the end of the snake.
  /// If false, the addition or removal is at the beginning of the snake.
  bool reverse = false;
}

/// Represents a range in two lists that needs to be solved.
///
/// This internal class is used when running Myers' algorithm without recursion.
class _Range {
  _Range([
    this.oldListStart = 0,
    this.oldListEnd = 0,
    this.newListStart = 0,
    this.newListEnd = 0,
  ]);
  int oldListStart = 0;
  int oldListEnd = 0;
  int newListStart = 0;
  int newListEnd = 0;
}

/// Represents an update that we skipped because it was a move.
///
/// When an update is skipped, it is tracked as other updates are dispatched
/// until the matching add/remove operation is found at which point the tracked
/// position is used to dispatch the update.
class _PostponedUpdate {
  _PostponedUpdate(
    this.posInOwnerList,
    this.currentPos, {
    required this.removal,
  });
  int posInOwnerList;
  int currentPos;
  bool removal;
}

/// This class holds the information about the result of a
/// [DiffUtil.calculateDiff] call.
///
/// You can consume the updates in a DiffResult via
/// [dispatchUpdatesTo].
class DiffResult {
  DiffResult._(
    this._callback,
    this._snakes,
    this._oldItemStatuses,
    this._newItemStatuses,
    this._detectMoves,
  ) : _oldListSize = _callback.oldListSize,
      _newListSize = _callback.newListSize {
    _addRootSnake();
    _findMatchingItems();
  }

  /// Signifies an item not present in the list.
  static const int noPosition = -1;

  // While reading the flags below, keep in mind that when multiple items move
  // in a list, Myers's may pick any of them as the anchor item and consider
  // that one NOT_CHANGED while picking others as additions and removals. This
  // is completely fine as we later detect all moves.
  //
  // Below, when an item is mentioned to stay in the same "location", it means
  // we won't dispatch a move/add/remove for it, it DOES NOT mean the item is
  // still in the same position.

  // item stayed the same.
  static const int _flagNotChanged = 1;
  // item stayed in the same location but changed.
  static const int _flagChanged = _flagNotChanged << 1;
  // Item has moved and also changed.
  static const int _flagMovedChanged = _flagChanged << 1;
  // Item has moved but did not change.
  static const int _flagMovedNotChanged = _flagMovedChanged << 1;
  // Ignore this update.
  // If this is an addition from the new list, it means the item is actually
  // removed from an earlier position and its move will be dispatched when we
  // process the matching removal from the old list.
  // If this is a removal from the old list, it means the item is actually
  // added back to an earlier index in the new list and we'll dispatch its move
  // when we are processing that addition.
  static const int _flagIgnore = _flagMovedNotChanged << 1;

  // since we are re-using the int arrays that were created in the Myers' step,
  // we mask change flags
  static const int _flagOffset = 5;
  static const int _flagMask = (1 << _flagOffset) - 1;

  // The Myers' snakes. At this point, we only care about their diagonal
  // sections.
  final List<_Snake> _snakes;

  // The list to keep oldItemStatuses. As we traverse old items, we assign
  // flags to them which also includes whether they were a real removal or a
  // move (and its new index).
  final List<int> _oldItemStatuses;
  // The list to keep newItemStatuses. As we traverse new items, we assign
  // flags to them which also includes whether they were a real addition or a
  // move(and its old index).
  final List<int> _newItemStatuses;
  // The callback that was given to calculate diff method.
  final DiffCallback _callback;

  final int _oldListSize;
  final int _newListSize;
  final bool _detectMoves;

  /// We always add a Snake to 0/0 so that we can run loops from end to
  /// beginning and be done when we run out of snakes.
  void _addRootSnake() {
    final firstSnake = _snakes.isEmpty ? null : _snakes.first;
    if (firstSnake == null || firstSnake.x != 0 || firstSnake.y != 0) {
      final root = _Snake()
        ..x = 0
        ..y = 0
        ..removal = false
        ..size = 0
        ..reverse = false;
      _snakes.insert(0, root);
    }
  }

  /// This method traverses each addition / removal and tries to match it to a
  /// previous removal / addition. This is how we detect move operations.
  ///
  /// This class also flags whether an item has been changed or not.
  ///
  /// DiffUtil does this pre-processing so that if it is running on a big list,
  /// it can be moved to background isolate where most of the expensive stuff
  /// will be calculated and kept in the statuses maps. DiffResult uses this
  /// pre-calculated information while dispatching the updates (which is
  /// probably being called on the main isolate).
  void _findMatchingItems() {
    var posOld = _oldListSize;
    var posNew = _newListSize;
    // traverse the matrix from right bottom to 0,0.
    for (var i = _snakes.length - 1; i >= 0; i--) {
      final snake = _snakes[i];
      final endX = snake.x + snake.size;
      final endY = snake.y + snake.size;
      if (_detectMoves) {
        while (posOld > endX) {
          // this is a removal. Check remaining snakes to see if this was added
          // before
          _findAddition(posOld, posNew, i);
          posOld--;
        }
        while (posNew > endY) {
          // this is an addition. Check remaining snakes to see if this was
          // removed before
          _findRemoval(posOld, posNew, i);
          posNew--;
        }
      }
      for (var j = 0; j < snake.size; j++) {
        // matching items. Check if it is changed or not
        final oldItemPos = snake.x + j;
        final newItemPos = snake.y + j;
        final theSame = _callback.areContentsTheSame(oldItemPos, newItemPos);
        final changeFlag = theSame ? _flagNotChanged : _flagChanged;
        _oldItemStatuses[oldItemPos] = (newItemPos << _flagOffset) | changeFlag;
        _newItemStatuses[newItemPos] = (oldItemPos << _flagOffset) | changeFlag;
      }
      posOld = snake.x;
      posNew = snake.y;
    }
  }

  void _findAddition(int x, int y, int snakeIndex) {
    if (_oldItemStatuses[x - 1] != 0) {
      return; // already set by a latter item
    }
    _findMatchingItem(x, y, snakeIndex, false);
  }

  void _findRemoval(int x, int y, int snakeIndex) {
    if (_newItemStatuses[y - 1] != 0) {
      return; // already set by a latter item
    }
    _findMatchingItem(x, y, snakeIndex, true);
  }

  /// Finds a matching item that is before the given coordinates in the matrix
  /// (before : left and above).
  ///
  /// [x] The x position in the matrix (position in the old list)
  /// [y] The y position in the matrix (position in the new list)
  /// [snakeIndex] The current snake index
  /// [removal] True if we are looking for a removal, false otherwise
  ///
  /// Returns true if such item is found.
  bool _findMatchingItem(int x, int y, int snakeIndex, bool removal) {
    final int myItemPos;
    int curX;
    int curY;
    if (removal) {
      myItemPos = y - 1;
      curX = x;
      curY = y - 1;
    } else {
      myItemPos = x - 1;
      curX = x - 1;
      curY = y;
    }
    for (var i = snakeIndex; i >= 0; i--) {
      final snake = _snakes[i];
      final endX = snake.x + snake.size;
      final endY = snake.y + snake.size;
      if (removal) {
        // check removals for a match
        for (var pos = curX - 1; pos >= endX; pos--) {
          if (_callback.areItemsTheSame(pos, myItemPos)) {
            // found!
            final theSame = _callback.areContentsTheSame(pos, myItemPos);
            final changeFlag = theSame
                ? _flagMovedNotChanged
                : _flagMovedChanged;
            _newItemStatuses[myItemPos] = (pos << _flagOffset) | _flagIgnore;
            _oldItemStatuses[pos] = (myItemPos << _flagOffset) | changeFlag;
            return true;
          }
        }
      } else {
        // check for additions for a match
        for (var pos = curY - 1; pos >= endY; pos--) {
          if (_callback.areItemsTheSame(myItemPos, pos)) {
            // found
            final theSame = _callback.areContentsTheSame(myItemPos, pos);
            final changeFlag = theSame
                ? _flagMovedNotChanged
                : _flagMovedChanged;
            _oldItemStatuses[x - 1] = (pos << _flagOffset) | _flagIgnore;
            _newItemStatuses[pos] = ((x - 1) << _flagOffset) | changeFlag;
            return true;
          }
        }
      }
      curX = snake.x;
      curY = snake.y;
    }
    return false;
  }

  /// Given a position in the old list, returns the position in the new list, or
  /// [noPosition] if it was removed.
  ///
  /// [oldListPosition] Position of item in old list
  ///
  /// Returns position of item in new list, or [noPosition] if not present.
  int convertOldPositionToNew(int oldListPosition) {
    if (oldListPosition < 0 || oldListPosition >= _oldListSize) {
      throw RangeError.index(
        oldListPosition,
        _oldItemStatuses,
        'oldListPosition',
      );
    }
    final status = _oldItemStatuses[oldListPosition];
    if ((status & _flagMask) == 0) {
      return noPosition;
    } else {
      return status >> _flagOffset;
    }
  }

  /// Given a position in the new list, returns the position in the old list, or
  /// [noPosition] if it was removed.
  ///
  /// [newListPosition] Position of item in new list
  ///
  /// Returns position of item in old list, or [noPosition] if not present.
  int convertNewPositionToOld(int newListPosition) {
    if (newListPosition < 0 || newListPosition >= _newListSize) {
      throw RangeError.index(
        newListPosition,
        _newItemStatuses,
        'newListPosition',
      );
    }
    final status = _newItemStatuses[newListPosition];
    if ((status & _flagMask) == 0) {
      return noPosition;
    } else {
      return status >> _flagOffset;
    }
  }

  /// Dispatches update operations to the given Callback.
  ///
  /// These updates are atomic such that the first update call affects every
  /// update call that comes after it.
  ///
  /// [updateCallback] The callback to receive the update operations.
  void dispatchUpdatesTo(ListUpdateCallback updateCallback) {
    final BatchingListUpdateCallback batchingCallback;
    if (updateCallback is BatchingListUpdateCallback) {
      batchingCallback = updateCallback;
    } else {
      batchingCallback = BatchingListUpdateCallback(updateCallback);
    }

    // These are add/remove ops that are converted to moves. We track their
    // positions until their respective update operations are processed.
    final postponedUpdates = <_PostponedUpdate>[];
    var posOld = _oldListSize;
    var posNew = _newListSize;
    for (var snakeIndex = _snakes.length - 1; snakeIndex >= 0; snakeIndex--) {
      final snake = _snakes[snakeIndex];
      final snakeSize = snake.size;
      final endX = snake.x + snakeSize;
      final endY = snake.y + snakeSize;
      if (endX < posOld) {
        _dispatchRemovals(
          postponedUpdates,
          batchingCallback,
          endX,
          posOld - endX,
          endX,
        );
      }

      if (endY < posNew) {
        _dispatchAdditions(
          postponedUpdates,
          batchingCallback,
          endX,
          posNew - endY,
          endY,
        );
      }
      for (var i = snakeSize - 1; i >= 0; i--) {
        if ((_oldItemStatuses[snake.x + i] & _flagMask) == _flagChanged) {
          batchingCallback.onChanged(
            snake.x + i,
            1,
            _callback.getChangePayload(snake.x + i, snake.y + i),
          );
        }
      }
      posOld = snake.x;
      posNew = snake.y;
    }
    batchingCallback.dispatchLastEvent();
  }

  static _PostponedUpdate? _removePostponedUpdate(
    List<_PostponedUpdate> updates,
    int pos,
    bool removal,
  ) {
    for (var i = updates.length - 1; i >= 0; i--) {
      final update = updates[i];
      if (update.posInOwnerList == pos && update.removal == removal) {
        updates.removeAt(i);
        for (var j = i; j < updates.length; j++) {
          // offset other ops since they swapped positions
          updates[j].currentPos += removal ? 1 : -1;
        }
        return update;
      }
    }
    return null;
  }

  void _dispatchAdditions(
    List<_PostponedUpdate> postponedUpdates,
    ListUpdateCallback updateCallback,
    int start,
    int count,
    int globalIndex,
  ) {
    if (!_detectMoves) {
      updateCallback.onInserted(start, count);
      return;
    }
    for (var i = count - 1; i >= 0; i--) {
      final status = _newItemStatuses[globalIndex + i] & _flagMask;
      switch (status) {
        case 0: // real addition
          updateCallback.onInserted(start, 1);
          for (final update in postponedUpdates) {
            update.currentPos += 1;
          }
        case _flagMovedChanged:
        case _flagMovedNotChanged:
          final pos = _newItemStatuses[globalIndex + i] >> _flagOffset;
          final update = _removePostponedUpdate(postponedUpdates, pos, true);
          // the item was moved from that position
          updateCallback.onMoved(update!.currentPos, start);
          if (status == _flagMovedChanged) {
            // also dispatch a change
            updateCallback.onChanged(
              start,
              1,
              _callback.getChangePayload(pos, globalIndex + i),
            );
          }
        case _flagIgnore: // ignoring this
          postponedUpdates.add(
            _PostponedUpdate(globalIndex + i, start, removal: false),
          );
        default:
          throw StateError(
            'unknown flag for '
            'pos ${globalIndex + i} ${status.toRadixString(2)}',
          );
      }
    }
  }

  void _dispatchRemovals(
    List<_PostponedUpdate> postponedUpdates,
    ListUpdateCallback updateCallback,
    int start,
    int count,
    int globalIndex,
  ) {
    if (!_detectMoves) {
      updateCallback.onRemoved(start, count);
      return;
    }
    for (var i = count - 1; i >= 0; i--) {
      final status = _oldItemStatuses[globalIndex + i] & _flagMask;
      switch (status) {
        case 0: // real removal
          updateCallback.onRemoved(start + i, 1);
          for (final update in postponedUpdates) {
            update.currentPos -= 1;
          }
        case _flagMovedChanged:
        case _flagMovedNotChanged:
          final pos = _oldItemStatuses[globalIndex + i] >> _flagOffset;
          final update = _removePostponedUpdate(postponedUpdates, pos, false);
          // the item was moved to that position. we do -1 because this is a
          // move not add and removing current item offsets the target move by 1
          updateCallback.onMoved(start + i, update!.currentPos - 1);
          if (status == _flagMovedChanged) {
            // also dispatch a change
            updateCallback.onChanged(
              update.currentPos - 1,
              1,
              _callback.getChangePayload(globalIndex + i, pos),
            );
          }
        case _flagIgnore: // ignoring this
          postponedUpdates.add(
            _PostponedUpdate(globalIndex + i, start + i, removal: true),
          );
        default:
          throw StateError(
            'unknown flag for '
            'pos ${globalIndex + i} ${status.toRadixString(2)}',
          );
      }
    }
  }
}

/// Main DiffUtil class containing the core algorithm implementation.
class DiffUtil {
  DiffUtil._(); // Private constructor - utility class

  static int _snakeComparator(_Snake a, _Snake b) {
    final cmpX = a.x - b.x;
    return cmpX == 0 ? a.y - b.y : cmpX;
  }

  /// Calculates the list of update operations that can convert one list into
  /// the other one.
  ///
  /// [callback] The callback that acts as a gateway to the backing list data
  ///
  /// Returns a DiffResult that contains the information about the edit sequence
  /// to convert the old list into the new list.
  static DiffResult calculateDiff(
    DiffCallback callback, {
    required bool detectMoves,
  }) => calculateDiffWithMoves(callback, detectMoves: detectMoves);

  /// Calculates the list of update operations that can convert one list into
  /// the other one.
  ///
  /// If your old and new lists are sorted by the same constraint and items
  /// never move (swap positions), you can disable move detection which takes
  /// O(N^2) time where N is the number of added, moved, removed items.
  ///
  /// [callback] The callback that acts as a gateway to the backing list data
  /// [detectMoves] True if DiffUtil should try to detect moved items, false
  /// otherwise.
  ///
  /// Returns a DiffResult that contains the information about the edit sequence
  /// to convert the old list into the new list.
  static DiffResult calculateDiffWithMoves(
    DiffCallback callback, {
    required bool detectMoves,
  }) {
    final oldSize = callback.oldListSize;
    final newSize = callback.newListSize;

    final snakes = <_Snake>[];

    // instead of a recursive implementation, we keep our own stack to avoid
    // potential stack overflow exceptions
    final stack = <_Range>[_Range(0, oldSize, 0, newSize)];

    final max = oldSize + newSize + (oldSize - newSize).abs();
    // allocate forward and backward k-lines. K lines are diagonal lines in the
    // matrix. (see the paper for details)
    // These arrays lines keep the max reachable position for each k-line.
    final forward = List<int>.filled(max * 2, 0);
    final backward = List<int>.filled(max * 2, 0);

    // We pool the ranges to avoid allocations for each recursive call.
    final rangePool = <_Range>[];
    while (stack.isNotEmpty) {
      final range = stack.removeLast();
      final snake = _diffPartial(
        callback,
        range.oldListStart,
        range.oldListEnd,
        range.newListStart,
        range.newListEnd,
        forward,
        backward,
        max,
      );
      if (snake != null) {
        if (snake.size > 0) {
          snakes.add(snake);
        }
        // offset the snake to convert its coordinates from the Range's area to
        // global
        snake
          ..x += range.oldListStart
          ..y += range.newListStart;

        // add new ranges for left and right
        final left = rangePool.isEmpty ? _Range() : rangePool.removeLast()
          ..oldListStart = range.oldListStart
          ..newListStart = range.newListStart;
        if (snake.reverse) {
          left
            ..oldListEnd = snake.x
            ..newListEnd = snake.y;
        } else {
          if (snake.removal) {
            left
              ..oldListEnd = snake.x - 1
              ..newListEnd = snake.y;
          } else {
            left
              ..oldListEnd = snake.x
              ..newListEnd = snake.y - 1;
          }
        }
        stack.add(left);

        // re-use range for right
        final right = range;
        if (snake.reverse) {
          if (snake.removal) {
            right
              ..oldListStart = snake.x + snake.size + 1
              ..newListStart = snake.y + snake.size;
          } else {
            right
              ..oldListStart = snake.x + snake.size
              ..newListStart = snake.y + snake.size + 1;
          }
        } else {
          right
            ..oldListStart = snake.x + snake.size
            ..newListStart = snake.y + snake.size;
        }
        stack.add(right);
      } else {
        rangePool.add(range);
      }
    }
    // sort snakes
    snakes.sort(_snakeComparator);

    return DiffResult._(
      callback,
      snakes,
      List<int>.filled(max * 2, 0),
      List<int>.filled(max * 2, 0),
      detectMoves,
    );
  }

  static _Snake? _diffPartial(
    DiffCallback cb,
    int startOld,
    int endOld,
    int startNew,
    int endNew,
    List<int> forward,
    List<int> backward,
    int kOffset,
  ) {
    final oldSize = endOld - startOld;
    final newSize = endNew - startNew;

    if (endOld - startOld < 1 || endNew - startNew < 1) {
      return null;
    }

    final delta = oldSize - newSize;
    final dLimit = (oldSize + newSize + 1) ~/ 2;

    // Fill arrays with appropriate values
    for (var i = kOffset - dLimit - 1; i <= kOffset + dLimit; i++) {
      if (i >= 0 && i < forward.length) forward[i] = 0;
    }
    for (
      var i = kOffset - dLimit - 1 + delta;
      i <= kOffset + dLimit + delta;
      i++
    ) {
      if (i >= 0 && i < backward.length) backward[i] = oldSize;
    }

    final checkInFwd = delta % 2 != 0;
    for (var d = 0; d <= dLimit; d++) {
      for (var k = -d; k <= d; k += 2) {
        // find forward path
        // we can reach k from k - 1 or k + 1. Check which one is further in
        // the graph
        int x;
        bool removal;
        final kIndex = kOffset + k;
        final kMinusIndex = kOffset + k - 1;
        final kPlusIndex = kOffset + k + 1;

        if (k == -d ||
            (k != d &&
                (kMinusIndex < 0 ||
                    kMinusIndex >= forward.length ||
                    kPlusIndex < 0 ||
                    kPlusIndex >= forward.length ||
                    forward[kMinusIndex] < forward[kPlusIndex]))) {
          x = kPlusIndex >= 0 && kPlusIndex < forward.length
              ? forward[kPlusIndex]
              : 0;
          removal = false;
        } else {
          x =
              (kMinusIndex >= 0 && kMinusIndex < forward.length
                  ? forward[kMinusIndex]
                  : 0) +
              1;
          removal = true;
        }
        // set y based on x
        var y = x - k;
        // move diagonal as long as items match
        while (x < oldSize &&
            y < newSize &&
            cb.areItemsTheSame(startOld + x, startNew + y)) {
          x++;
          y++;
        }
        if (kIndex >= 0 && kIndex < forward.length) {
          forward[kIndex] = x;
        }
        if (checkInFwd && k >= delta - d + 1 && k <= delta + d - 1) {
          final backwardIndex = kOffset + k;
          if (kIndex >= 0 &&
              kIndex < forward.length &&
              backwardIndex >= 0 &&
              backwardIndex < backward.length &&
              forward[kIndex] >= backward[backwardIndex]) {
            final outSnake = _Snake()
              ..x = backward[backwardIndex]
              ..y = backward[backwardIndex] - k
              ..size = forward[kIndex] - backward[backwardIndex]
              ..removal = removal
              ..reverse = false;
            return outSnake;
          }
        }
      }
      for (var k = -d; k <= d; k += 2) {
        // find reverse path at k + delta, in reverse
        final backwardK = k + delta;
        int x;
        bool removal;
        final backwardKIndex = kOffset + backwardK;
        final backwardKMinusIndex = kOffset + backwardK - 1;
        final backwardKPlusIndex = kOffset + backwardK + 1;

        if (backwardK == d + delta ||
            (backwardK != -d + delta &&
                (backwardKMinusIndex < 0 ||
                    backwardKMinusIndex >= backward.length ||
                    backwardKPlusIndex < 0 ||
                    backwardKPlusIndex >= backward.length ||
                    backward[backwardKMinusIndex] <
                        backward[backwardKPlusIndex]))) {
          x = backwardKMinusIndex >= 0 && backwardKMinusIndex < backward.length
              ? backward[backwardKMinusIndex]
              : oldSize;
          removal = false;
        } else {
          x =
              (backwardKPlusIndex >= 0 && backwardKPlusIndex < backward.length
                  ? backward[backwardKPlusIndex]
                  : oldSize) -
              1;
          removal = true;
        }

        // set y based on x
        var y = x - backwardK;
        // move diagonal as long as items match
        while (x > 0 &&
            y > 0 &&
            cb.areItemsTheSame(startOld + x - 1, startNew + y - 1)) {
          x--;
          y--;
        }
        if (backwardKIndex >= 0 && backwardKIndex < backward.length) {
          backward[backwardKIndex] = x;
        }
        if (!checkInFwd && k + delta >= -d && k + delta <= d) {
          final forwardIndex = kOffset + backwardK;
          if (forwardIndex >= 0 &&
              forwardIndex < forward.length &&
              backwardKIndex >= 0 &&
              backwardKIndex < backward.length &&
              forward[forwardIndex] >= backward[backwardKIndex]) {
            final outSnake = _Snake()
              ..x = backward[backwardKIndex]
              ..y = backward[backwardKIndex] - backwardK
              ..size = forward[forwardIndex] - backward[backwardKIndex]
              ..removal = removal
              ..reverse = true;
            return outSnake;
          }
        }
      }
    }
    throw StateError(
      'DiffUtil hit an unexpected case while trying to calculate'
      ' the optimal path. Please make sure your data is not changing during the'
      ' diff calculation.',
    );
  }
}
