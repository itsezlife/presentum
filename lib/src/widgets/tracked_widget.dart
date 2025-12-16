import 'package:flutter/widgets.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/build_context_extension.dart';

/// {@template presentum_tracked_widget}
/// A widget that automatically tracks presentation lifecycle events.
///
/// This widget automatically calls [markShown] when it first builds,
/// if [trackVisibility] is true.
///
/// This widget uses [PageStorage] to remember whether it has already
/// tracked the "shown" event to avoid duplicate tracking when the widget is
/// rebuilt.
/// {@endtemplate}
class PresentumTrackedWidget<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends StatefulWidget {
  /// {@macro presentum_tracked_widget}
  const PresentumTrackedWidget({
    required this.item,
    required this.builder,
    this.onDismiss,
    this.trackVisibility = true,
    super.key,
  });

  /// The presentum item to track.
  final TItem item;

  /// Builder for the child widget.
  final Widget Function(BuildContext context, TItem item) builder;

  /// Callback when the widget is dismissed (if using dismissible wrapper).
  final VoidCallback? onDismiss;

  /// Whether to automatically track when the widget is shown.
  /// Defaults to true.
  final bool trackVisibility;

  @override
  State<PresentumTrackedWidget<TItem, S, V>> createState() =>
      _PresentumTrackedWidgetState<TItem, S, V>();
}

class _PresentumTrackedWidgetState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends State<PresentumTrackedWidget<TItem, S, V>> {
  late bool _hasTrackedShown;

  String get _pageStorageKey => 'presentum_tracked_widget_${widget.item.id}';

  @override
  void initState() {
    super.initState();
    final hasTrackedShown =
        PageStorage.of(context).readState(context, identifier: _pageStorageKey)
            as bool? ??
        false;
    _hasTrackedShown = hasTrackedShown;
    if (widget.trackVisibility && !_hasTrackedShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.presentum<TItem, S, V>().markShown(widget.item);
        _hasTrackedShown = true;
        PageStorage.of(
          context,
        ).writeState(context, true, identifier: _pageStorageKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.item);
}
