import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentation.dart';

/// Extension methods for [BuildContext].
extension PresentationBuildContextExtension on BuildContext {
  /// Receives the [Presentum] instance from the elements tree.
  Presentum<TResolved, S>
  presentum<TResolved extends Identifiable, S extends PresentumSurface>() =>
      InheritedPresentum.of<TResolved, S>(this, listen: false).presentum;
}
