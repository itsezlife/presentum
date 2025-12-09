import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Bindings for the Presentum engine.
class PresentumBindings<
  TResolved extends Identifiable,
  S extends PresentumSurface
> {
  /// {@macro presentum_bindings}
  const PresentumBindings({required this.surfaceOf, required this.variantOf});

  /// Get the surface for an item.
  final S Function(TResolved item) surfaceOf;

  /// Get the variant for an item.
  final Enum Function(TResolved item) variantOf;
}
