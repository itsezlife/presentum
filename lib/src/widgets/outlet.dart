import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/widgets/outlet/composition_items_combiner.dart';
import 'package:presentum/src/widgets/outlet/slot_items_collector.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

export 'package:presentum/src/widgets/outlet/composition_items_combiner.dart';
export 'package:presentum/src/widgets/outlet/slot_items_collector.dart';

/// Builder that receives [BuildContext] and a presentation item.
typedef PresentumOutletBuilder<T> =
    Widget Function(BuildContext context, T item);

/// Builder that returns a placeholder when a surface has no active item.
typedef PresentumOutletPlaceholderBuilder =
    Widget Function(BuildContext context);

/// {@template presentum_outlet}
/// Renders the active item for [surface] from [slots].
/// {@endtemplate}
class PresentumOutlet<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet}
  const PresentumOutlet({
    required this.slots,
    required this.surface,
    required this.builder,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  });

  /// Slot state owned by the host controller.
  final PresentumSlotState<TItem, S, V> slots;

  /// The surface to render items from.
  final S surface;

  /// Builder for the active item.
  final PresentumOutletBuilder<TItem> builder;

  /// Placeholder when the surface has no active item.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

  @override
  State<PresentumOutlet<TItem, S, V>> createState() =>
      _PresentumOutletState<TItem, S, V>();
}

class _PresentumOutletState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumOutlet<TItem, S, V>> {
  TItem? _active;

  @override
  void initState() {
    super.initState();
    _active = widget.slots.activeFor(widget.surface);
  }

  @override
  void didUpdateWidget(PresentumOutlet<TItem, S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots == oldWidget.slots &&
        widget.surface == oldWidget.surface) {
      return;
    }

    final next = widget.slots.activeFor(widget.surface);
    if (next?.id != _active?.id) {
      setState(() => _active = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _active;
    if (item != null) {
      return InheritedPresentumItem<TItem, S, V>(
        item: item,
        child: widget.builder(context, item),
      );
    }
    return widget.placeholderBuilder(context);
  }
}

/// {@template presentum_outlet_composition}
/// Renders one or more items from a surface slot in [slots].
/// {@endtemplate}
class PresentumOutlet$Composition<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition}
  const PresentumOutlet$Composition({
    required this.slots,
    required this.surface,
    this.collector,
    this.builder,
    this.compositeBuilder,
    this.buildWhen,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         builder != null || compositeBuilder != null,
         'builder or compositeBuilder must be provided',
       );

  /// Slot state owned by the host controller.
  final PresentumSlotState<TItem, S, V> slots;

  /// The surface to render items from.
  final S surface;

  /// Selects items from the slot; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem, S, V>? collector;

  /// Builder for the resolved item list.
  final PresentumOutletBuilder<List<TItem>>? builder;

  /// Builder that handles empty and non-empty lists.
  final PresentumOutletBuilder<List<TItem>>? compositeBuilder;

  /// Optional rebuild gate.
  final bool Function(List<TItem> previousItems, List<TItem> currentItems)?
  buildWhen;

  /// Placeholder when [builder] is used and items are empty.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

  @override
  State<PresentumOutlet$Composition<TItem, S, V>> createState() =>
      _PresentumOutlet$CompositionState<TItem, S, V>();
}

class _PresentumOutlet$CompositionState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumOutlet$Composition<TItem, S, V>> {
  List<TItem> _items = <TItem>[];

  @override
  void initState() {
    super.initState();
    _items = _collectItems();
  }

  @override
  void didUpdateWidget(PresentumOutlet$Composition<TItem, S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots == oldWidget.slots &&
        widget.surface == oldWidget.surface &&
        identical(widget.collector, oldWidget.collector)) {
      return;
    }

    final items = _collectItems();
    final defaultBuildWhen = !ListEquality<TItem>().equals(_items, items);
    if (widget.buildWhen?.call(_items, items) ?? defaultBuildWhen) {
      setState(() => _items = items);
    }
  }

  List<TItem> _collectItems() {
    final collector =
        widget.collector ?? PresentumSlotItemsCollector<TItem, S, V>.single();
    return collector.collect(widget.slots, widget.surface);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compositeBuilder case final compositeBuilder?) {
      return compositeBuilder(context, _items);
    }
    if (_items.isEmpty) return widget.placeholderBuilder(context);
    return widget.builder!.call(context, _items);
  }
}

/// {@template presentum_outlet_composition2}
/// Cross-domain composition outlet for two slot states.
/// {@endtemplate}
class PresentumOutlet$Composition2<
  TItem1 extends PresentumItem<PresentumPayload<S1, V1>, S1, V1>,
  TItem2 extends PresentumItem<PresentumPayload<S2, V2>, S2, V2>,
  S1 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  S2 extends PresentumSurface,
  V2 extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition2}
  const PresentumOutlet$Composition2({
    required this.slots1,
    required this.slots2,
    required this.surface1,
    required this.surface2,
    this.collector1,
    this.collector2,
    this.combiner,
    this.builder,
    this.compositeBuilder,
    this.buildWhen,
    this.debounceDuration = _defaultDebounceDuration,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         builder != null || compositeBuilder != null,
         'builder or compositeBuilder must be provided',
       );

  /// First domain slot state.
  final PresentumSlotState<TItem1, S1, V1> slots1;

  /// Second domain slot state.
  final PresentumSlotState<TItem2, S2, V2> slots2;

  /// Surface from [slots1].
  final S1 surface1;

  /// Surface from [slots2].
  final S2 surface2;

  /// Collector for [slots1]; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem1, S1, V1>? collector1;

  /// Collector for [slots2]; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem2, S2, V2>? collector2;

  /// Merges per-domain lists; defaults to highest-priority item.
  final PresentumCompositionItemsCombiner2<TItem1, TItem2>? combiner;

  /// Builder for the combined item list.
  final PresentumOutletBuilder<List<PresentumItem>>? builder;

  /// Debounce rapid slot updates.
  final Duration debounceDuration;

  /// Builder that handles empty and non-empty lists.
  final PresentumOutletBuilder<List<PresentumItem>>? compositeBuilder;

  /// Optional rebuild gate.
  final bool Function(
    List<PresentumItem> previousItems,
    List<PresentumItem> currentItems,
  )?
  buildWhen;

  /// Placeholder when [builder] is used and items are empty.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

  static const _defaultDebounceDuration = Duration(milliseconds: 16);

  @override
  State<PresentumOutlet$Composition2<TItem1, TItem2, S1, V1, S2, V2>>
  createState() =>
      _PresentumOutlet$Composition2State<TItem1, TItem2, S1, V1, S2, V2>();
}

class _PresentumOutlet$Composition2State<
  TItem1 extends PresentumItem<PresentumPayload<S1, V1>, S1, V1>,
  TItem2 extends PresentumItem<PresentumPayload<S2, V2>, S2, V2>,
  S1 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  S2 extends PresentumSurface,
  V2 extends PresentumVisualVariant
>
    extends
        State<PresentumOutlet$Composition2<TItem1, TItem2, S1, V1, S2, V2>> {
  List<PresentumItem> _items = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _items = _resolveItems();
  }

  @override
  void didUpdateWidget(
    PresentumOutlet$Composition2<TItem1, TItem2, S1, V1, S2, V2> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (_composition2ConfigUnchanged(oldWidget)) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, _applyResolvedItems);
  }

  bool _composition2ConfigUnchanged(
    PresentumOutlet$Composition2<TItem1, TItem2, S1, V1, S2, V2> oldWidget,
  ) =>
      widget.slots1 == oldWidget.slots1 &&
      widget.slots2 == oldWidget.slots2 &&
      widget.surface1 == oldWidget.surface1 &&
      widget.surface2 == oldWidget.surface2 &&
      identical(widget.collector1, oldWidget.collector1) &&
      identical(widget.collector2, oldWidget.collector2) &&
      identical(widget.combiner, oldWidget.combiner);

  void _applyResolvedItems() {
    if (!mounted) return;

    final resolvedItems = _resolveItems();
    final defaultBuildWhen = !const ListEquality<PresentumItem>().equals(
      _items,
      resolvedItems,
    );
    if (widget.buildWhen?.call(_items, resolvedItems) ?? defaultBuildWhen) {
      setState(() => _items = resolvedItems);
    }
  }

  List<PresentumItem> _resolveItems() {
    final collector1 =
        widget.collector1 ??
        PresentumSlotItemsCollector<TItem1, S1, V1>.single();
    final collector2 =
        widget.collector2 ??
        PresentumSlotItemsCollector<TItem2, S2, V2>.single();
    final combiner =
        widget.combiner ??
        PresentumCompositionItemsCombiner2<TItem1, TItem2>.single();

    return combiner.combine(
      collector1.collect(widget.slots1, widget.surface1),
      collector2.collect(widget.slots2, widget.surface2),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compositeBuilder case final compositeBuilder?) {
      return compositeBuilder(context, _items);
    }
    if (_items.isEmpty) return widget.placeholderBuilder(context);
    return widget.builder!.call(context, _items);
  }
}

/// {@template presentum_outlet_composition3}
/// Cross-domain composition outlet for three slot states.
/// {@endtemplate}
class PresentumOutlet$Composition3<
  TItem1 extends PresentumItem<PresentumPayload<S1, V1>, S1, V1>,
  TItem2 extends PresentumItem<PresentumPayload<S2, V2>, S2, V2>,
  TItem3 extends PresentumItem<PresentumPayload<S3, V3>, S3, V3>,
  S1 extends PresentumSurface,
  S2 extends PresentumSurface,
  S3 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  V2 extends PresentumVisualVariant,
  V3 extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition3}
  const PresentumOutlet$Composition3({
    required this.slots1,
    required this.slots2,
    required this.slots3,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    this.collector1,
    this.collector2,
    this.collector3,
    this.combiner,
    this.builder,
    this.compositeBuilder,
    this.buildWhen,
    this.debounceDuration = _defaultDebounceDuration,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         (builder != null) ^ (compositeBuilder != null),
         'Either builder or compositeBuilder must be provided, but not both.',
       );

  /// First domain slot state.
  final PresentumSlotState<TItem1, S1, V1> slots1;

  /// Second domain slot state.
  final PresentumSlotState<TItem2, S2, V2> slots2;

  /// Third domain slot state.
  final PresentumSlotState<TItem3, S3, V3> slots3;

  /// Surface from [slots1].
  final S1 surface1;

  /// Surface from [slots2].
  final S2 surface2;

  /// Surface from [slots3].
  final S3 surface3;

  /// Collector for [slots1]; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem1, S1, V1>? collector1;

  /// Collector for [slots2]; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem2, S2, V2>? collector2;

  /// Collector for [slots3]; defaults to single-item selection.
  final PresentumSlotItemsCollector<TItem3, S3, V3>? collector3;

  /// Merges per-domain lists; defaults to highest-priority item.
  final PresentumCompositionItemsCombiner3<TItem1, TItem2, TItem3>? combiner;

  /// Builder for the combined item list.
  final PresentumOutletBuilder<List<PresentumItem>>? builder;

  /// Builder that handles empty and non-empty lists.
  final PresentumOutletBuilder<List<PresentumItem>>? compositeBuilder;

  /// Debounce rapid slot updates.
  final Duration debounceDuration;

  /// Optional rebuild gate.
  final bool Function(
    List<PresentumItem> previousItems,
    List<PresentumItem> currentItems,
  )?
  buildWhen;

  /// Placeholder when [builder] is used and items are empty.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

  static const _defaultDebounceDuration = Duration(milliseconds: 16);

  @override
  State<
    PresentumOutlet$Composition3<TItem1, TItem2, TItem3, S1, S2, S3, V1, V2, V3>
  >
  createState() =>
      _PresentumOutlet$Composition3State<
        TItem1,
        TItem2,
        TItem3,
        S1,
        S2,
        S3,
        V1,
        V2,
        V3
      >();
}

class _PresentumOutlet$Composition3State<
  TItem1 extends PresentumItem<PresentumPayload<S1, V1>, S1, V1>,
  TItem2 extends PresentumItem<PresentumPayload<S2, V2>, S2, V2>,
  TItem3 extends PresentumItem<PresentumPayload<S3, V3>, S3, V3>,
  S1 extends PresentumSurface,
  S2 extends PresentumSurface,
  S3 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  V2 extends PresentumVisualVariant,
  V3 extends PresentumVisualVariant
>
    extends
        State<
          PresentumOutlet$Composition3<
            TItem1,
            TItem2,
            TItem3,
            S1,
            S2,
            S3,
            V1,
            V2,
            V3
          >
        > {
  List<PresentumItem> _items = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _items = _resolveItems();
  }

  @override
  void didUpdateWidget(
    PresentumOutlet$Composition3<TItem1, TItem2, TItem3, S1, S2, S3, V1, V2, V3>
    oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (_composition3ConfigUnchanged(oldWidget)) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, _applyResolvedItems);
  }

  bool _composition3ConfigUnchanged(
    PresentumOutlet$Composition3<TItem1, TItem2, TItem3, S1, S2, S3, V1, V2, V3>
    oldWidget,
  ) =>
      widget.slots1 == oldWidget.slots1 &&
      widget.slots2 == oldWidget.slots2 &&
      widget.slots3 == oldWidget.slots3 &&
      widget.surface1 == oldWidget.surface1 &&
      widget.surface2 == oldWidget.surface2 &&
      widget.surface3 == oldWidget.surface3 &&
      identical(widget.collector1, oldWidget.collector1) &&
      identical(widget.collector2, oldWidget.collector2) &&
      identical(widget.collector3, oldWidget.collector3) &&
      identical(widget.combiner, oldWidget.combiner);

  void _applyResolvedItems() {
    if (!mounted) return;

    final resolvedItems = _resolveItems();
    final defaultBuildWhen = !const ListEquality<PresentumItem>().equals(
      _items,
      resolvedItems,
    );
    if (widget.buildWhen?.call(_items, resolvedItems) ?? defaultBuildWhen) {
      setState(() => _items = resolvedItems);
    }
  }

  List<PresentumItem> _resolveItems() {
    final collector1 =
        widget.collector1 ??
        PresentumSlotItemsCollector<TItem1, S1, V1>.single();
    final collector2 =
        widget.collector2 ??
        PresentumSlotItemsCollector<TItem2, S2, V2>.single();
    final collector3 =
        widget.collector3 ??
        PresentumSlotItemsCollector<TItem3, S3, V3>.single();
    final combiner =
        widget.combiner ??
        PresentumCompositionItemsCombiner3<TItem1, TItem2, TItem3>.single();

    return combiner.combine(
      collector1.collect(widget.slots1, widget.surface1),
      collector2.collect(widget.slots2, widget.surface2),
      collector3.collect(widget.slots3, widget.surface3),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compositeBuilder case final compositeBuilder?) {
      return compositeBuilder(context, _items);
    }
    if (_items.isEmpty) return widget.placeholderBuilder(context);
    return widget.builder!.call(context, _items);
  }
}
