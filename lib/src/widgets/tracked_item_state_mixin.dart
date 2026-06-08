import 'package:flutter/material.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template tracked_item_source_mixin}
/// Source mixin for deferred "shown" tracking.
/// {@endtemplate}
abstract mixin class ITrackedItemSourceMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// The presentation item rendered by this widget.
  abstract final TItem item;

  /// Called once when the item is first shown (after the first frame).
  ///
  /// Not called again for the same [item] while [pageStorageKey] state
  /// persists.
  abstract final void Function(TItem item) onShown;

  /// When false, [onShown] is never called. Defaults to true on host widgets.
  abstract final bool trackVisibility;
}

/// {@template tracked_item_host_mixin}
/// Provides [pageStorageKey] so [TrackedItemStateMixin] can deduplicate
/// [onShown] across rebuilds and route restores within the same [PageStorage]
/// bucket.
/// {@endtemplate}
mixin TrackedItemHostMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    on StatefulWidget
    implements ITrackedItemSourceMixin<TItem, S, V> {
  /// PageStorage identifier for this item's "already shown" flag.
  ///
  /// Override when multiple tracked widgets for the same [item.id] need
  /// independent keys (e.g. different surfaces).
  String get pageStorageKey => 'presentum_tracked_item:${item.id}';
}

/// {@template tracked_item_state_mixin}
/// State mixin that fires [ITrackedItemSourceMixin.onShown] once per item.
///
/// Uses [PageStorage] to avoid duplicate [onShown] when the widget rebuilds or
/// remounts in the same route. Tracking runs in a post-frame callback so layout
/// has completed before the shown side-effect fires.
/// {@endtemplate}
mixin TrackedItemStateMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
  W extends TrackedItemHostMixin<TItem, S, V>
>
    on State<W> {
  late bool _hasTrackedShown;

  PageStorageBucket _bucketOf(BuildContext context) => PageStorage.of(context);

  bool? _readShownFlag(BuildContext context) =>
      _bucketOf(context).readState(context, identifier: widget.pageStorageKey)
          as bool?;

  void _writeShownFlag(BuildContext context, {required bool value}) =>
      _bucketOf(
        context,
      ).writeState(context, value, identifier: widget.pageStorageKey);

  @override
  void initState() {
    super.initState();
    _hasTrackedShown = _readShownFlag(context) ?? false;
    if (widget.trackVisibility && !_hasTrackedShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _trackShown());
    }
  }

  void _trackShown() {
    if (!mounted || _hasTrackedShown) return;
    widget.onShown(widget.item);
    _hasTrackedShown = true;
    _writeShownFlag(context, value: true);
  }
}
