import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

/// Any presentation item that may appear in a composition outlet.
typedef PresentumCompositionItem =
    PresentumItem<
      PresentumPayload<PresentumSurface, PresentumVisualVariant>,
      PresentumSurface,
      PresentumVisualVariant
    >;

/// {@template presentum_composition_items_combiner2}
/// Merges item lists from two domains for composition outlets.
/// {@endtemplate}
abstract class PresentumCompositionItemsCombiner2<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem
> {
  /// {@macro presentum_composition_items_combiner2}
  const PresentumCompositionItemsCombiner2();

  /// Highest-priority item across both lists (first non-empty list wins).
  const factory PresentumCompositionItemsCombiner2.single() =
      PresentumCompositionItemsCombiner2$Single<TItem1, TItem2>;

  /// Concatenation of both lists.
  const factory PresentumCompositionItemsCombiner2.all() =
      PresentumCompositionItemsCombiner2$All<TItem1, TItem2>;

  /// Custom merge of per-domain lists.
  factory PresentumCompositionItemsCombiner2.custom(
    List<PresentumItem> Function(List<TItem1> items1, List<TItem2> items2)
    combine,
  ) => PresentumCompositionItemsCombiner2$Custom<TItem1, TItem2>(combine);

  /// Merges [items1] and [items2] for the outlet builder.
  List<PresentumItem> combine(List<TItem1> items1, List<TItem2> items2);
}

/// {@macro presentum_composition_items_combiner2}
final class PresentumCompositionItemsCombiner2$Single<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner2<TItem1, TItem2> {
  /// {@macro presentum_composition_items_combiner2}
  const PresentumCompositionItemsCombiner2$Single();

  @override
  List<PresentumItem> combine(List<TItem1> items1, List<TItem2> items2) {
    if (items1.isNotEmpty) return <PresentumItem>[items1.first];
    if (items2.isNotEmpty) return <PresentumItem>[items2.first];
    return <PresentumItem>[];
  }
}

/// {@macro presentum_composition_items_combiner2}
final class PresentumCompositionItemsCombiner2$All<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner2<TItem1, TItem2> {
  /// {@macro presentum_composition_items_combiner2}
  const PresentumCompositionItemsCombiner2$All();

  @override
  List<PresentumItem> combine(List<TItem1> items1, List<TItem2> items2) =>
      <PresentumItem>[...items1, ...items2];
}

/// {@macro presentum_composition_items_combiner2}
final class PresentumCompositionItemsCombiner2$Custom<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner2<TItem1, TItem2> {
  /// {@macro presentum_composition_items_combiner2}
  const PresentumCompositionItemsCombiner2$Custom(this._combine);

  final List<PresentumItem> Function(List<TItem1> items1, List<TItem2> items2)
  _combine;

  @override
  List<PresentumItem> combine(List<TItem1> items1, List<TItem2> items2) =>
      _combine(items1, items2);
}

/// {@template presentum_composition_items_combiner3}
/// Merges item lists from three domains for composition outlets.
/// {@endtemplate}
abstract class PresentumCompositionItemsCombiner3<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem,
  TItem3 extends PresentumCompositionItem
> {
  /// {@macro presentum_composition_items_combiner3}
  const PresentumCompositionItemsCombiner3();

  /// Highest-priority item across all three lists.
  const factory PresentumCompositionItemsCombiner3.single() =
      PresentumCompositionItemsCombiner3$Single<TItem1, TItem2, TItem3>;

  /// Concatenation of all three lists.
  const factory PresentumCompositionItemsCombiner3.all() =
      PresentumCompositionItemsCombiner3$All<TItem1, TItem2, TItem3>;

  /// Custom merge of per-domain lists.
  factory PresentumCompositionItemsCombiner3.custom(
    List<PresentumItem> Function(
      List<TItem1> items1,
      List<TItem2> items2,
      List<TItem3> items3,
    )
    combine,
  ) => PresentumCompositionItemsCombiner3$Custom<TItem1, TItem2, TItem3>(
    combine,
  );

  /// Merges [items1], [items2], and [items3] for the outlet builder.
  List<PresentumItem> combine(
    List<TItem1> items1,
    List<TItem2> items2,
    List<TItem3> items3,
  );
}

/// {@macro presentum_composition_items_combiner3}
final class PresentumCompositionItemsCombiner3$Single<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem,
  TItem3 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner3<TItem1, TItem2, TItem3> {
  /// {@macro presentum_composition_items_combiner3}
  const PresentumCompositionItemsCombiner3$Single();

  @override
  List<PresentumItem> combine(
    List<TItem1> items1,
    List<TItem2> items2,
    List<TItem3> items3,
  ) {
    if (items1.isNotEmpty) return <PresentumItem>[items1.first];
    if (items2.isNotEmpty) return <PresentumItem>[items2.first];
    if (items3.isNotEmpty) return <PresentumItem>[items3.first];
    return <PresentumItem>[];
  }
}

/// {@macro presentum_composition_items_combiner3}
final class PresentumCompositionItemsCombiner3$All<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem,
  TItem3 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner3<TItem1, TItem2, TItem3> {
  /// {@macro presentum_composition_items_combiner3}
  const PresentumCompositionItemsCombiner3$All();

  @override
  List<PresentumItem> combine(
    List<TItem1> items1,
    List<TItem2> items2,
    List<TItem3> items3,
  ) => <PresentumItem>[...items1, ...items2, ...items3];
}

/// {@macro presentum_composition_items_combiner3}
final class PresentumCompositionItemsCombiner3$Custom<
  TItem1 extends PresentumCompositionItem,
  TItem2 extends PresentumCompositionItem,
  TItem3 extends PresentumCompositionItem
>
    extends PresentumCompositionItemsCombiner3<TItem1, TItem2, TItem3> {
  /// {@macro presentum_composition_items_combiner3}
  const PresentumCompositionItemsCombiner3$Custom(this._combine);

  final List<PresentumItem> Function(
    List<TItem1> items1,
    List<TItem2> items2,
    List<TItem3> items3,
  )
  _combine;

  @override
  List<PresentumItem> combine(
    List<TItem1> items1,
    List<TItem2> items2,
    List<TItem3> items3,
  ) => _combine(items1, items2, items3);
}
