/// Read-only eligibility and runtime facts passed into pipeline steps.
///
/// Host controllers pre-fill this map before calling the pipeline. Steps must
/// not mutate it.
typedef PresentumContext = Map<String, Object?>;
