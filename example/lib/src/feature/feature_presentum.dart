import 'package:control/control.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/feature/controller/feature_controller.dart';
import 'package:flutter/material.dart';

class FeaturePresentum extends StatelessWidget {
  const FeaturePresentum({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deps = Dependencies.of(context);
    return ControllerScope(
      () => FeatureController(
        storage: PersistentPresentumStorage(prefs: deps.sharedPreferences),
        catalog: deps.featureCatalog,
        prefs: deps.featurePreferences,
      ),
      child: child,
    );
  }
}
