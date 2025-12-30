import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/build_context_extension.dart';
import 'package:presentum/src/widgets/presentum_context.dart';

/// Builder function that receives the [BuildContext] and the [TItem] item.
typedef PresentumOutletBuilder<T> =
    Widget Function(BuildContext context, T item);

/// Builder function that receives the [BuildContext] and returns a placeholder
/// widget.
typedef PresentumOutletPlaceholderBuilder =
    Widget Function(BuildContext context);

/// {@template presentum_outlet}
/// Outlet that can render items from a surface of the same type.
/// {@endtemplate}
class PresentumOutlet<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet}
  const PresentumOutlet({
    required this.surface,
    required this.builder,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  });

  /// The surface to render items from.
  final S surface;

  /// Builder function that receives the [BuildContext] and the [TItem]
  /// item.
  final PresentumOutletBuilder<TItem> builder;

  /// Builder function that receives the [BuildContext] and returns a
  /// placeholder widget.
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
  late final PresentumStateObserver<TItem, S, V> _observer;
  TItem? _lastItem;

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TItem, S, V>().observer;

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
      if (mounted) setState(() {});
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
      return InheritedPresentumItem<TItem, S, V>(
        item: item,
        child: widget.builder.call(context, item),
      );
    }
    return widget.placeholderBuilder(context);
  }
}

/// How a [PresentumOutlet] should select items from a surface slot.
enum OutletGroupMode {
  /// Only the highest priority item (active or first in queue).
  single,

  /// All items from the slot (active + queue).
  all,

  /// Let the resolver decide how to select items from the full list.
  custom,
}

/// Resolver function that decides how to select items from a surface slot.
typedef CompositionItemsResolver<TItem> =
    List<TItem> Function(List<TItem> items);

/// {@template presentum_outlet_composition}
/// Outlet that can render items from a surface of the same type.
/// {@endtemplate}
class PresentumOutlet$Composition<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_outlet_composition}
  const PresentumOutlet$Composition({
    required this.surface,
    this.builder,
    this.compositeBuilder,
    this.resolver,
    this.surfaceMode = OutletGroupMode.single,
    this.buildWhen,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         builder != null || compositeBuilder != null,
         'builder or compositeBuilder must be provided',
       );

  /// The surface to render items from.
  final S surface;

  /// How to select items from the slot (active + queue).
  final OutletGroupMode surfaceMode;

  /// Custom resolver that decides how to select items from the slot.
  final CompositionItemsResolver<TItem>? resolver;

  /// Builder that receives the list of items from the slot.
  final PresentumOutletBuilder<List<TItem>>? builder;

  /// Builder that receives the [BuildContext] and the list of items from the
  /// slot combined and takes the responsibility of rendering them
  /// and hanlding an empty state.
  ///
  /// By default, the widget [builder] is used to render the items and
  /// [placeholderBuilder] is used to render a placeholder when the items are
  /// empty.
  final PresentumOutletBuilder<List<TItem>>? compositeBuilder;

  /// Function that decides whether to rebuild the widget when the items change.
  final bool Function(List<TItem> previousItems, List<TItem> currentItems)?
  buildWhen;

  /// Builder function that receives the [BuildContext] and returns a
  /// placeholder widget.
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
    extends State<PresentumOutlet$Composition<TItem, S, V>>
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TItem, S, V> _observer;
  List<TItem> _items = <TItem>[];

  @override
  void initState() {
    super.initState();
    _observer = context.presentum<TItem, S, V>().observer;
    _onStateChange();
    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items = collectItemsForSlot<TItem, S, V>(
      widget.surface,
      _observer,
      widget.surfaceMode,
      resolver: widget.resolver,
    );

    // Check if items changed
    final defaultBuildWhen = !ListEquality<TItem>().equals(_items, items);
    if (widget.buildWhen?.call(_items, items) ?? defaultBuildWhen) {
      _items = items;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _observer.removeListener(_onStateChange);
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

/// Resolver function that decides how to combine items from two different
/// presentums.
typedef CompositionItemsResolver2<TItem1, TItem2> =
    List<PresentumItem> Function(List<TItem1> items1, List<TItem2> items2);

/// {@template presentum_outlet_composition2}
/// Cross-presentum composition outlet for two different presentums.
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
    required this.surface1,
    required this.surface2,
    required this.resolver,
    this.builder,
    this.compositeBuilder,
    this.buildWhen,
    this.resolverMode = OutletGroupMode.single,
    this.surfaceMode1 = OutletGroupMode.single,
    this.surfaceMode2 = OutletGroupMode.single,
    this.resolver1,
    this.resolver2,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         builder != null || compositeBuilder != null,
         'builder or compositeBuilder must be provided',
       );

  /// The surface to render items from the first presentum.
  final S1 surface1;

  /// The surface to render items from the second presentum.
  final S2 surface2;

  /// How to select items from the first surface.
  final OutletGroupMode surfaceMode1;

  /// How to select items from the second surface.
  final OutletGroupMode surfaceMode2;

  /// How to select items from both surfaces.
  final OutletGroupMode resolverMode;

  /// Custom resolver that decides how to combine items from both presentums.
  final CompositionItemsResolver2<TItem1, TItem2>? resolver;

  /// Custom resolver that decides how to select items from the first surface.
  final CompositionItemsResolver<TItem1>? resolver1;

  /// Custom resolver that decides how to select items from the second surface.
  final CompositionItemsResolver<TItem2>? resolver2;

  /// Builder that receives the list of items from the two presentums combined.
  final PresentumOutletBuilder<List<PresentumItem>>? builder;

  /// Builder that receives the [BuildContext] and the list of items from the
  /// two presentums combined and takes the responsibility of rendering them
  /// and hanlding an empty state.
  ///
  /// By default, the widget [builder] is used to render the items and
  /// [placeholderBuilder] is used to render a placeholder when the items are
  /// empty.
  final PresentumOutletBuilder<List<PresentumItem>>? compositeBuilder;

  /// Function that decides whether to rebuild the widget when the items change.
  final bool Function(
    List<PresentumItem> previousItems,
    List<PresentumItem> currentItems,
  )?
  buildWhen;

  /// Builder function that receives the [BuildContext] and returns a
  /// placeholder widget.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

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
    extends State<PresentumOutlet$Composition2<TItem1, TItem2, S1, V1, S2, V2>>
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TItem1, S1, V1> _observer1;
  late final PresentumStateObserver<TItem2, S2, V2> _observer2;
  List<PresentumItem> _items = [];

  @override
  void initState() {
    super.initState();
    _observer1 = context.presentum<TItem1, S1, V1>().observer;
    _observer2 = context.presentum<TItem2, S2, V2>().observer;

    _onStateChange();
    _observer1.addListener(_onStateChange);
    _observer2.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items1 = collectItemsForSlot<TItem1, S1, V1>(
      widget.surface1,
      _observer1,
      widget.surfaceMode1,
      resolver: widget.resolver1,
    );
    final items2 = collectItemsForSlot<TItem2, S2, V2>(
      widget.surface2,
      _observer2,
      widget.surfaceMode2,
      resolver: widget.resolver2,
    );

    final allItems = <PresentumItem>[...items1, ...items2];

    final resolvedItems = switch (widget.resolverMode) {
      OutletGroupMode.single => <PresentumItem>[allItems.first],
      OutletGroupMode.all => allItems,
      OutletGroupMode.custom => widget.resolver!.call(items1, items2),
    };

    final defaultBuildWhen = !const ListEquality<PresentumItem>().equals(
      _items,
      resolvedItems,
    );
    if (widget.buildWhen?.call(_items, resolvedItems) ?? defaultBuildWhen) {
      _items = resolvedItems;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _observer1.removeListener(_onStateChange);
    _observer2.removeListener(_onStateChange);
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

/// Resolver function that decides how to combine items from three different
/// presentums.
typedef CompositionItemsResolver3<TItem1, TItem2, TItem3> =
    List<PresentumItem> Function(
      List<TItem1> items1,
      List<TItem2> items2,
      List<TItem3> items3,
    );

/// {@template presentum_outlet_composition3}
/// Cross-presentum composition outlet for three different presentums.
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
    required this.surface1,
    required this.surface2,
    required this.surface3,
    this.resolverMode = OutletGroupMode.single,
    this.surfaceMode1 = OutletGroupMode.single,
    this.surfaceMode2 = OutletGroupMode.single,
    this.surfaceMode3 = OutletGroupMode.single,
    this.resolver,
    this.resolver1,
    this.resolver2,
    this.resolver3,
    this.builder,
    this.compositeBuilder,
    this.buildWhen,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    super.key,
  }) : assert(
         (builder != null) ^ (compositeBuilder != null),
         'Either builder or compositeBuilder must be provided, but not both.',
       ),
       assert(
         resolverMode != OutletGroupMode.custom || resolver != null,
         'resolver must be provided when surfaceMode is custom.',
       );

  /// The surface to render items from the first presentum.
  final S1 surface1;

  /// The surface to render items from the second presentum.
  final S2 surface2;

  /// The surface to render items from the third presentum.
  final S3 surface3;

  /// How to combine items from all three presentums.
  final OutletGroupMode resolverMode;

  /// How to select items from the first surface.
  final OutletGroupMode surfaceMode1;

  /// How to select items from the second surface.
  final OutletGroupMode surfaceMode2;

  /// How to select items from the third surface.
  final OutletGroupMode surfaceMode3;

  /// Custom resolver that decides how to combine items from all three
  /// presentums.
  final CompositionItemsResolver3<TItem1, TItem2, TItem3>? resolver;

  /// Custom resolver for the first surface.
  final CompositionItemsResolver<TItem1>? resolver1;

  /// Custom resolver for the second surface.
  final CompositionItemsResolver<TItem2>? resolver2;

  /// Custom resolver for the third surface.
  final CompositionItemsResolver<TItem3>? resolver3;

  /// Builder that receives the list of items from the three presentums
  /// combined.
  final PresentumOutletBuilder<List<PresentumItem>>? builder;

  /// Composite builder that receives the list of items from the three
  /// presentums combined.
  final PresentumOutletBuilder<List<PresentumItem>>? compositeBuilder;

  /// Function that decides whether to rebuild the widget when the items change.
  final bool Function(
    List<PresentumItem> previousItems,
    List<PresentumItem> currentItems,
  )?
  buildWhen;

  /// Builder function that receives the [BuildContext] and returns a
  /// placeholder widget.
  final PresentumOutletPlaceholderBuilder placeholderBuilder;

  static Widget _defaultPlaceholderBuilder(BuildContext context) =>
      const SizedBox.shrink();

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
        >
    with PresentumOutlet$CompositionMixin {
  late final PresentumStateObserver<TItem1, S1, V1> _observer1;
  late final PresentumStateObserver<TItem2, S2, V2> _observer2;
  late final PresentumStateObserver<TItem3, S3, V3> _observer3;
  List<PresentumItem> _items = [];

  @override
  void initState() {
    super.initState();
    _observer1 = context.presentum<TItem1, S1, V1>().observer;
    _observer2 = context.presentum<TItem2, S2, V2>().observer;
    _observer3 = context.presentum<TItem3, S3, V3>().observer;

    _onStateChange();
    _observer1.addListener(_onStateChange);
    _observer2.addListener(_onStateChange);
    _observer3.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items1 = collectItemsForSlot<TItem1, S1, V1>(
      widget.surface1,
      _observer1,
      widget.surfaceMode1,
      resolver: widget.resolver1,
    );
    final items2 = collectItemsForSlot<TItem2, S2, V2>(
      widget.surface2,
      _observer2,
      widget.surfaceMode2,
      resolver: widget.resolver2,
    );
    final items3 = collectItemsForSlot<TItem3, S3, V3>(
      widget.surface3,
      _observer3,
      widget.surfaceMode3,
      resolver: widget.resolver3,
    );

    final allItems = <PresentumItem>[...items1, ...items2, ...items3];

    final resolvedItems = switch (widget.resolverMode) {
      OutletGroupMode.single => <PresentumItem>[allItems.first],
      OutletGroupMode.all => allItems,
      OutletGroupMode.custom => widget.resolver!.call(items1, items2, items3),
    };

    final defaultBuildWhen = !const ListEquality<PresentumItem>().equals(
      _items,
      resolvedItems,
    );
    if (widget.buildWhen?.call(_items, resolvedItems) ?? defaultBuildWhen) {
      _items = resolvedItems;
      if (mounted) setState(() {});
    }
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
    if (widget.compositeBuilder case final compositeBuilder?) {
      return compositeBuilder(context, _items);
    }
    if (_items.isEmpty) return widget.placeholderBuilder(context);
    return widget.builder!.call(context, _items);
  }
}

/// Mixin that contains the logic for collecting items from a surface slot.
mixin PresentumOutlet$CompositionMixin {
  /// Collect items from a surface slot.
  List<T> collectItemsForSlot<
    T extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(
    S surface,
    PresentumStateObserver<T, S, V> observer,
    OutletGroupMode mode, {
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
      OutletGroupMode.all => all,
      OutletGroupMode.custom => resolver!.call(all),
    };
  }
}
