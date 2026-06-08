/// Domain library for conditional UI presentations.
///
/// Campaigns, banners, popups, and related slot-driven widgets.
library;

export 'src/events/analytics.dart';
export 'src/events/event_handler.dart';
export 'src/events/events.dart';
export 'src/events/lifecycle.dart';
export 'src/resolver/context.dart';
export 'src/resolver/pipeline.dart';
export 'src/resolver/presentum_resolver.dart';
export 'src/resolver/presentum_resolver_step.dart';
export 'src/resolver/step_input.dart';
export 'src/state/payload.dart';
export 'src/state/slot.dart';
export 'src/state/slot_state.dart';
export 'src/state/slots_history.dart';
export 'src/state/surface.dart';
export 'src/storage/storage.dart';
export 'src/transitions/slots_diff.dart';
export 'src/transitions/slots_transition.dart';
export 'src/utils/diff_util.dart';
export 'src/utils/diff_util_helpers.dart';
export 'src/widgets/build_context_extension.dart';
export 'src/widgets/outlet.dart';
export 'src/widgets/popup_host.dart';
export 'src/widgets/presentum_context.dart';
export 'src/widgets/slot_listener.dart';
export 'src/widgets/tracked_item_state_mixin.dart';
export 'src/widgets/tracked_widget.dart';
