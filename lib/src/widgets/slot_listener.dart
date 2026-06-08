import 'package:flutter/widgets.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';

/// Called when the active item on [surface] changes.
typedef PresentumSlotListenerCallback<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> = void Function(TItem? previous, TItem? current);

/// {@template presentum_slot_listener}
/// Widget analogue of the removed active-surface observer mixin.
/// {@endtemplate}
class PresentumSlotListener<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_slot_listener}
  const PresentumSlotListener({
    required this.slots,
    required this.surface,
    required this.listener,
    required this.child,
    this.listenWhen,
    super.key,
  });

  /// Current slot state for this domain.
  final PresentumSlotState<TItem, S, V> slots;

  /// Surface whose active item is observed.
  final S surface;

  /// Fired when the active item changes.
  final PresentumSlotListenerCallback<TItem, S, V> listener;

  /// Optional gate — return false to skip [listener].
  final bool Function(TItem? previous, TItem? current)? listenWhen;

  /// Subtree rendered below this listener.
  final Widget child;

  @override
  State<PresentumSlotListener<TItem, S, V>> createState() =>
      _PresentumSlotListenerState<TItem, S, V>();
}

class _PresentumSlotListenerState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumSlotListener<TItem, S, V>> {
  TItem? _previousActive;

  @override
  void initState() {
    super.initState();
    _previousActive = widget.slots.activeFor(widget.surface);
  }

  @override
  void didUpdateWidget(PresentumSlotListener<TItem, S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots == oldWidget.slots) return;

    final current = widget.slots.activeFor(widget.surface);
    final previous = _previousActive;
    final shouldListen =
        widget.listenWhen?.call(previous, current) ??
        previous?.id != current?.id;

    if (shouldListen) {
      _previousActive = current;
      widget.listener(previous, current);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
