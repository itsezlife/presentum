import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/build_context_extension.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

/// Builder function that receives the [BuildContext] and the [TResolved] item.
typedef PresentumBuilder<TResolved> =
    Widget Function(BuildContext context, TResolved item);

/// {@template presentum_outlet}
/// Outlet that can render items from a surface of the same type.
/// {@endtemplate}
abstract class PresentumOutlet<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet}
  const PresentumOutlet({required this.surface, super.key});

  /// The surface to render items from.
  final S surface;

  /// Builder function that receives the [BuildContext] and the [TResolved]
  /// item.
  abstract final PresentumBuilder<TResolved> builder;

  @override
  State<PresentumOutlet<TResolved, S, V>> createState() =>
      _PresentumOutletState<TResolved, S, V>();
}

class _PresentumOutletState<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumOutlet<TResolved, S, V>> {
  late final PresentumStateObserver<TResolved, S, V> _observer;
  TResolved? _lastItem;

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TResolved, S, V>().observer;

    // Handle initial state evaluation.
    _onStateChange();

    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final state = _observer.value;
    final slot = state.slots[widget.surface];
    final currentItem = slot?.active;

    if (currentItem != _lastItem) {
      _lastItem = currentItem;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _observer.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastItem case final item?) {
      return InheritedPresentumResolvedVariant<TResolved, S, V>(
        item: item,
        child: widget.builder(context, item),
      );
    }
    return const SizedBox.shrink();
  }
}

/// How a [PresentumOutlet] should select items from a surface slot.
enum OutletGroupMode {
  /// Only the highest priority item (active or first in queue).
  single,

  /// Up to `maxItems` items from active + queue.
  multiple,

  /// Let the resolver decide how to select items from the full list.
  custom,
}

/// How a [PresentumOutlet$Composition] should merge items from multiple
/// surfaces.
enum CompositionMergeMode {
  /// Concatenate all items from all surfaces in order.
  concatenate,

  /// Only items from the first surface that has any.
  firstNonEmpty,

  /// Let the resolver decide how to merge items from the full list.
  custom,
}

/// Resolver function that decides how to select items from a surface slot.
typedef CompositionItemsResolver<TResolved> =
    List<TResolved> Function(List<TResolved> items);

/// {@template presentum_outlet_composition}
/// Outlet that can render items from multiple surfaces of the same type.
/// {@endtemplate}
class PresentumOutlet$Composition<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition}
  const PresentumOutlet$Composition({
    required this.surface,
    required this.builder,
    this.resolver,
    this.mergeMode = CompositionMergeMode.concatenate,
    this.surfaceMode = OutletGroupMode.single,
    this.maxItems = 2,
    super.key,
  }) : assert(
         resolver != null || mergeMode != CompositionMergeMode.custom,
         'resolver must be provided when mergeMode is custom',
       );

  /// The surface to render items from.
  final S surface;

  /// How to merge items from the slot (active + queue).
  final CompositionMergeMode mergeMode;

  /// How to select items from the slot (active + queue).
  final OutletGroupMode surfaceMode;

  /// Maximum number of items to include in final result.
  final int maxItems;

  /// Custom resolver that decides how to select items from the slot.
  final CompositionItemsResolver<TResolved>? resolver;

  /// Builder that receives the list of items from the slot.
  final Widget Function(BuildContext context, List<TResolved> items) builder;

  @override
  State<PresentumOutlet$Composition<TResolved, S, V>> createState() =>
      _PresentumOutlet$CompositionState<TResolved, S, V>();
}

class _PresentumOutlet$CompositionState<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumOutlet$Composition<TResolved, S, V>>
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TResolved, S, V> _observer;
  List<TResolved> _items = <TResolved>[];

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TResolved, S, V>().observer;
    _onStateChange();
    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items = collectItemsForSlot<TResolved, S, V>(
      widget.surface,
      _observer,
      widget.surfaceMode,
      maxItems: widget.maxItems,
      resolver: widget.resolver,
    );

    // Check if items changed
    if (_items.length == items.length && _items.every(items.contains)) {
      return;
    }

    _items = items;
    setState(() {});
  }

  @override
  void dispose() {
    _observer.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return widget.builder(context, _items);
  }
}

/// Resolver function that decides how to combine items from two different
/// presentums.
typedef CompositionItemsResolver2<TResolved1, TResolved2> =
    List<TResolved1> Function(List<TResolved1> items1, List<TResolved2> items2);

/// {@template presentum_outlet_composition2}
/// Cross-presentum composition outlet for two different presentums.
/// {@endtemplate}
class PresentumOutlet$Composition2<
  TResolved1 extends ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>,
  TResolved2 extends ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>,
  S1 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  S2 extends PresentumSurface,
  V2 extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition2}
  const PresentumOutlet$Composition2({
    required this.surface1,
    required this.surface2,
    required this.resolver,
    required this.builder,
    this.surfaceMode1 = OutletGroupMode.single,
    this.surfaceMode2 = OutletGroupMode.single,
    this.mergeMode1 = CompositionMergeMode.concatenate,
    this.mergeMode2 = CompositionMergeMode.concatenate,
    this.resolver1,
    this.resolver2,
    super.key,
  });

  /// The surface to render items from the first presentum.
  final S1 surface1;

  /// The surface to render items from the second presentum.
  final S2 surface2;

  /// How to select items from the first surface.
  final OutletGroupMode surfaceMode1;

  /// How to select items from the second surface.
  final OutletGroupMode surfaceMode2;

  /// How to merge items from the first surface.
  final CompositionMergeMode mergeMode1;

  /// How to merge items from the second surface.
  final CompositionMergeMode mergeMode2;

  /// Custom resolver that decides how to select items from the first surface.
  final CompositionItemsResolver<TResolved1>? resolver1;

  /// Custom resolver that decides how to select items from the second surface.
  final CompositionItemsResolver<TResolved2>? resolver2;

  /// Custom resolver that decides how to combine items from both presentums.
  final CompositionItemsResolver2<TResolved1, TResolved2> resolver;

  /// Builder that receives the list of items from the two presentums combined.
  final Widget Function(
    BuildContext context,
    List<ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>> items1,
    List<ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>> items2,
  )
  builder;

  @override
  State<PresentumOutlet$Composition2<TResolved1, TResolved2, S1, V1, S2, V2>>
  createState() =>
      _PresentumOutlet$Composition2State<
        TResolved1,
        TResolved2,
        S1,
        V1,
        S2,
        V2
      >();
}

class _PresentumOutlet$Composition2State<
  TResolved1 extends ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>,
  TResolved2 extends ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>,
  S1 extends PresentumSurface,
  V1 extends PresentumVisualVariant,
  S2 extends PresentumSurface,
  V2 extends PresentumVisualVariant
>
    extends
        State<
          PresentumOutlet$Composition2<TResolved1, TResolved2, S1, V1, S2, V2>
        >
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TResolved1, S1, V1> _observer1;
  late final PresentumStateObserver<TResolved2, S2, V2> _observer2;
  List<ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>> _items1 = [];
  List<ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>> _items2 = [];

  @override
  void initState() {
    super.initState();
    _observer1 = context.presentum<TResolved1, S1, V1>().observer;
    _observer2 = context.presentum<TResolved2, S2, V2>().observer;

    _onStateChange();
    _observer1.addListener(_onStateChange);
    _observer2.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items1 = collectItemsForSlot<TResolved1, S1, V1>(
      widget.surface1,
      _observer1,
      widget.surfaceMode1,
      resolver: widget.resolver1,
    );
    final items2 = collectItemsForSlot<TResolved2, S2, V2>(
      widget.surface2,
      _observer2,
      widget.surfaceMode2,
      resolver: widget.resolver2,
    );

    if (_items1.length == items1.length &&
        _items1.every(items1.contains) &&
        _items2.length == items2.length &&
        _items2.every(items2.contains)) {
      return;
    }

    _items1 = items1;
    _items2 = items2;
    setState(() {});
  }

  @override
  void dispose() {
    _observer1.removeListener(_onStateChange);
    _observer2.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items1.isEmpty && _items2.isEmpty) return const SizedBox.shrink();
    return widget.builder(context, _items1, _items2);
  }
}

/// Resolver function that decides how to combine items from three different
/// presentums.
typedef CompositionItemsResolver3<TResolved1, TResolved2, TResolved3> =
    List<TResolved1> Function(
      List<TResolved1> items1,
      List<TResolved2> items2,
      List<TResolved3> items3,
    );

/// {@template presentum_outlet_composition3}
/// Cross-presentum composition outlet for three different presentums.
/// {@endtemplate}
class PresentumOutlet$Composition3<
  TResolved1 extends ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>,
  TResolved2 extends ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>,
  TResolved3 extends ResolvedPresentumVariant<PresentumPayload<S3, V3>, S3, V3>,
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
    required this.surfaces1,
    required this.surfaces2,
    required this.surfaces3,
    required this.resolver,
    required this.builder,
    this.surfaceMode1 = OutletGroupMode.single,
    this.surfaceMode2 = OutletGroupMode.single,
    this.surfaceMode3 = OutletGroupMode.single,
    this.mergeMode1 = CompositionMergeMode.concatenate,
    this.mergeMode2 = CompositionMergeMode.concatenate,
    this.mergeMode3 = CompositionMergeMode.concatenate,
    super.key,
  });

  /// The surfaces to render items from the first presentum.
  final List<S1> surfaces1;

  /// The surfaces to render items from the second presentum.
  final List<S2> surfaces2;

  /// The surfaces to render items from the third presentum.
  final List<S3> surfaces3;

  /// How to select items from the first surface.
  final OutletGroupMode surfaceMode1;

  /// How to select items from the second surface.
  final OutletGroupMode surfaceMode2;

  /// How to select items from the third surface.
  final OutletGroupMode surfaceMode3;

  /// How to merge items from the first surface.
  final CompositionMergeMode mergeMode1;

  /// How to merge items from the second surface.
  final CompositionMergeMode mergeMode2;

  /// How to merge items from the third surface.
  final CompositionMergeMode mergeMode3;

  /// Custom resolver that decides how to combine items from all three
  /// presentums.
  final CompositionItemsResolver3<TResolved1, TResolved2, TResolved3> resolver;

  /// Builder that receives the list of items from the three presentums
  /// combined.
  final Widget Function(
    BuildContext context,
    List<ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>> items1,
    List<ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>> items2,
    List<ResolvedPresentumVariant<PresentumPayload<S3, V3>, S3, V3>> items3,
  )
  builder;

  @override
  State<
    PresentumOutlet$Composition3<
      TResolved1,
      TResolved2,
      TResolved3,
      S1,
      S2,
      S3,
      V1,
      V2,
      V3
    >
  >
  createState() =>
      _PresentumOutlet$Composition3State<
        TResolved1,
        TResolved2,
        TResolved3,
        S1,
        S2,
        S3,
        V1,
        V2,
        V3
      >();
}

class _PresentumOutlet$Composition3State<
  TResolved1 extends ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>,
  TResolved2 extends ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>,
  TResolved3 extends ResolvedPresentumVariant<PresentumPayload<S3, V3>, S3, V3>,
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
            TResolved1,
            TResolved2,
            TResolved3,
            S1,
            S2,
            S3,
            V1,
            V2,
            V3
          >
        >
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TResolved1, S1, V1> _observer1;
  late final PresentumStateObserver<TResolved2, S2, V2> _observer2;
  late final PresentumStateObserver<TResolved3, S3, V3> _observer3;
  List<ResolvedPresentumVariant<PresentumPayload<S1, V1>, S1, V1>> _items1 = [];
  List<ResolvedPresentumVariant<PresentumPayload<S2, V2>, S2, V2>> _items2 = [];
  List<ResolvedPresentumVariant<PresentumPayload<S3, V3>, S3, V3>> _items3 = [];

  @override
  void initState() {
    super.initState();
    _observer1 = context.presentum<TResolved1, S1, V1>().observer;
    _observer2 = context.presentum<TResolved2, S2, V2>().observer;
    _observer3 = context.presentum<TResolved3, S3, V3>().observer;

    _onStateChange();
    _observer1.addListener(_onStateChange);
    _observer2.addListener(_onStateChange);
    _observer3.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items1 = collectItems<TResolved1, S1, V1>(
      widget.surfaces1,
      _observer1,
      widget.surfaceMode1,
      widget.mergeMode1,
    );
    final items2 = collectItems<TResolved2, S2, V2>(
      widget.surfaces2,
      _observer2,
      widget.surfaceMode2,
      widget.mergeMode2,
    );
    final items3 = collectItems<TResolved3, S3, V3>(
      widget.surfaces3,
      _observer3,
      widget.surfaceMode3,
      widget.mergeMode3,
    );

    // final resolved = widget.resolver(items1, items2, items3);

    if (_items1.length == items1.length &&
        _items1.every(items1.contains) &&
        _items2.length == items2.length &&
        _items2.every(items2.contains) &&
        _items3.length == items3.length &&
        _items3.every(items3.contains)) {
      return;
    }

    _items1 = items1;
    _items2 = items2;
    _items3 = items3;
    setState(() {});
  }

  @override
  void dispose() {
    _observer1.removeListener(_onStateChange);
    _observer2.removeListener(_onStateChange);
    _observer3.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items1.isEmpty && _items2.isEmpty && _items3.isEmpty) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, _items1, _items2, _items3);
  }
}

/// Mixin that contains the logic for collecting items from a surface slot.
mixin PresentumOutlet$CompositionMixin {
  /// Collect items from a surface slot.
  List<T> collectItemsForSlot<
    T extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(
    S surface,
    PresentumStateObserver<T, S, V> observer,
    OutletGroupMode mode, {
    int maxItems = 2,
    CompositionItemsResolver<T>? resolver,
  }) {
    final state = observer.value;
    final slot = state.slots[surface];
    final all = <T>[];

    if (slot?.active case final active?) {
      all.add(active);
    }
    if (slot?.queue case final queue?) {
      all.addAll(queue);
    }

    if (all.isEmpty) return <T>[];

    return switch (mode) {
      OutletGroupMode.single => <T>[all.first],
      OutletGroupMode.multiple => all.take(maxItems).toList(growable: false),
      OutletGroupMode.custom => resolver!.call(all),
    };
  }

  /// Collect items from multiple surfaces.
  List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>> collectItems<
    T extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(
    List<S> surfaces,
    PresentumStateObserver<T, S, V> observer,
    OutletGroupMode mode,
    CompositionMergeMode mergeMode, {
    int? maxItems,
    CompositionItemsResolver<
      ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>
    >?
    resolver,
  }) {
    // Collect items from each surface according to surfaceMode
    final surfaceItems =
        <S, List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>>{};

    for (final surface in surfaces) {
      final state = observer.value;
      final slot = state.slots[surface];
      final all = <ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>[];

      if (slot?.active case final active?) {
        all.add(active);
      }
      if (slot?.queue case final queue?) {
        all.addAll(queue);
      }

      List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>
      surfaceResult;
      switch (mode) {
        case OutletGroupMode.single:
          surfaceResult = all.isEmpty
              ? <ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>[]
              : <ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>[
                  all.first,
                ];
        case OutletGroupMode.multiple:
          surfaceResult = all.take(2).toList(growable: false);
        case OutletGroupMode.custom:
          surfaceResult = all;
      }

      surfaceItems[surface] = surfaceResult;
    }

    return _mergeItems(
      surfaceItems.values.toList(),
      mergeMode,
      maxItems: maxItems,
      resolver: resolver,
    );
  }

  /// Merge items from multiple surfaces.
  List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>
  _mergeItems<S extends PresentumSurface, V extends PresentumVisualVariant>(
    List<List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>>
    itemLists,
    CompositionMergeMode mergeMode, {
    int? maxItems,
    List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>> Function(
      List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>> items,
    )?
    resolver,
  }) {
    assert(
      resolver != null || mergeMode != CompositionMergeMode.custom,
      'resolver must be provided when mergeMode is custom',
    );
    // Merge items according to mergeMode
    List<ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>> result;
    switch (mergeMode) {
      case CompositionMergeMode.concatenate:
        result = itemLists.expand((items) => items).toList();

      case CompositionMergeMode.firstNonEmpty:
        result = itemLists.firstWhere(
          (items) => items.isNotEmpty,
          orElse: () =>
              <ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>>[],
        );

      case CompositionMergeMode.custom:
        result = resolver!.call(itemLists.expand((items) => items).toList());
    }

    // Apply maxItems limit if specified
    if (maxItems case final max?) {
      result = result.take(max).toList(growable: false);
    }

    return result;
  }
}
