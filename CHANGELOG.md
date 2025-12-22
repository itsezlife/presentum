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
