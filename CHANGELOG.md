## 0.3.5

- **Feat**: Added pattern matching to `SlotChange` with `map()`, `maybeMap()`, and `mapOrNull()` methods
- **Feat**: Added convenience getters `isActivated`, `isDeactivated`, `isQueued`, `isDequeued` to `SlotChange`
- **Docs**: Split advanced documentation into separate guides for surface observers and popup hosts
- **Docs**: Updated transition observers documentation with pattern matching examples and production examples
- **Docs**: Clarified when to use transition observers vs surface observers
- **Example**: Refactored `MaintenanceSurfaceObserver` from widget-based to `MaintenanceTransitionObserver` for proper separation of concerns

## 0.3.4

- **BREAKING**: `PresentumPopupSurfaceStateMixin` now requires `PresentumActiveSurfaceItemObserverMixin` as a mixin (changed from `implements` to `on`)
- **Feat**: Added default implementation for `markDismissed()` method
- **Refactor**: Removed duplicate observer state management and lifecycle methods

## 0.3.3

- **BREAKING**: Refactored `PresentumPopupSurfaceStateMixin.present()` to return `PopupPresentResult` enum instead of `bool?`
  - Added `PopupPresentResult` enum with three states: `userDismissed`, `systemDismissed`, `notPresented`
  - The `present()` method now has clear, type-safe return values instead of nullable boolean
  - `notPresented` is returned when widget is not mounted, preventing unnecessary `markDismissed()` calls
  - Mixin only calls `markDismissed()` for `systemDismissed` results
- **Feat**: Exported `PresentumPopupSurfaceStateMixin` and related enums in main library
- **Docs**: Updated popup hosts documentation with new enum-based API examples

## 0.3.2

- **Docs**: added three comprehensive docs showcasing business-logic-first examples
  for New Year, user preferences and milestones.
- **Feat**: added complete cross-platform example application showcasing various capabilities and best practices with Presentum.
- **Fix**: fixed critical bugs with `PresentumPopupSurfaceStateMixin`
- **Feat**: added various useful features and configurations to the `PresentumPopupSurfaceStateMixin` to better resolve duplications and queues.
- **Chore**: added environmental logs that enabled if `presentum.logs` are enabled to log useful debug/development information.
- **Chore**: added `toString` implementation to the `PresentumSlot` for better loggin.

## 0.3.1+1

- **Chore**: renamed `popup_host.dart` file to `popup_surface_state_mixin.dart`

## 0.3.1

- **Feat**: Added PresentumPopupSurfaceStateMixin mixin to streamline popup presentum displaying with reactive observing, presenting and dismissing upon declarative removing from the active state slot.

## 0.3.0

- **Docs**: Added comprehensive docs with Mintlify

## 0.2.6

- **Chore**: Removed `moved` callback from `setCandidatesWithDiff` because detectMoves
  is false regardless.

## 0.2.5

- **Feat(transitions):** add observer system for lifecycle hooks
- **Feat(eligibility):** add conditions, rules, and metadata extractors
- **Feat(widgets):** add auto-tracking widget with visibility management
- **Feat(diff):** add Myers algorithm for efficient list operations
- **Feat(events):** add event-based architecture for state lifecycle (shown, dismissed, converted)
- **Feat(controller):** add `setCandidatesWithDiff` helper for minimal boilerplate
- **BREAKING:** rename `PresentumVariant` -> `ResolvedPresentumVariant`
- **BREAKING:** rename `InheritedPresentation` -> `InheritedPresentum`
- **BREAKING:** introduce generic `V` type parameter for visual variants
- **BREAKING:** change `getDismissedUntil` -> `getDismissedAt`
- **BREAKING:** remove `Identifiable` class and bindings system
- **Refactor(state):** implement equality and hashCode for core classes
- **Refactor(errors):** enhance error handling with stack traces and typed exceptions
- **Refactor(widgets):** make `PresentumOutlet` concrete with placeholder builder support
- **Test:** add comprehensive tests for transitions
- **Refactor(types):** improve type safety with generic type parameters
- **Fix(diff):** correct candidate list initialization in diff operations
- **Fix(diff):** use resolved candidates in diff calculation
- **Fix(engine):** remove problematic `late final` declarations
- **Docs:** add comprehensive Mintlify documentation site
- **Docs:** add AI integration guides (Cursor, Claude, Windsurf)
- **Docs:** update README with examples and architecture overview

## 0.0.1-pre.0

- Initial publication
