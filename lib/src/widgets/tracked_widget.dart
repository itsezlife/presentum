// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/widgets.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/widgets/tracked_item_state_mixin.dart';

/// Ready-made wrapper that tracks when a [PresentumItem] is first shown.
///
/// {@template presentum_tracked_widget}
/// Delegates tracking to [TrackedItemHostMixin] + [TrackedItemStateMixin].
/// Calls [onShown] once per [item] (per [pageStorageKey]) after the first
/// frame when [trackVisibility] is true.
///
/// ```dart
/// PresentumTrackedWidget(
///   item: item,
///   onShown: (item) => storage.recordShown(
///     item.id,
///     surface: item.surface,
///     variant: item.variant,
///     at: DateTime.now(),
///   ),
///   builder: (context, item) => CampaignBanner(item: item),
/// )
/// ```
///
/// **Custom widget** — same mixins, no wrapper:
///
/// ```dart
/// class CampaignBanner extends StatefulWidget
///     with TrackedItemHostMixin<CampaignItem, CampaignSurface, CampaignVariant> {
///   const CampaignBanner({required this.item, required this.onShown, super.key});
///   @override final CampaignItem item;
///   @override final void Function(CampaignItem item) onShown;
///   @override final bool trackVisibility = true;
/// }
///
/// class _CampaignBannerState extends State<CampaignBanner>
///     with TrackedItemStateMixin<
///       CampaignItem,
///       CampaignSurface,
///       CampaignVariant,
///       CampaignBanner
///     > {
///   @override
///   Widget build(BuildContext context) => ...;
/// }
/// ```
/// {@endtemplate}
class PresentumTrackedWidget<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget
    with TrackedItemHostMixin<TItem, S, V> {
  /// {@macro presentum_tracked_widget}
  const PresentumTrackedWidget({
    required this.item,
    required this.onShown,
    required this.builder,
    this.trackVisibility = true,
    super.key,
  });

  @override
  final TItem item;

  @override
  final void Function(TItem item) onShown;

  @override
  final bool trackVisibility;

  /// Builds the visible presentation UI for [item].
  final Widget Function(BuildContext context, TItem item) builder;

  @override
  State<PresentumTrackedWidget<TItem, S, V>> createState() =>
      _PresentumTrackedWidgetState<TItem, S, V>();
}

class _PresentumTrackedWidgetState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumTrackedWidget<TItem, S, V>>
    with
        TrackedItemStateMixin<
          TItem,
          S,
          V,
          PresentumTrackedWidget<TItem, S, V>
        > {
  @override
  Widget build(BuildContext context) => widget.builder(context, widget.item);
}
