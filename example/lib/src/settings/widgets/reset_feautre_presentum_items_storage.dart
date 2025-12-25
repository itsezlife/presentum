import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class ResetFeaturePresentumItemsStorage extends StatefulWidget {
  const ResetFeaturePresentumItemsStorage({super.key});

  @override
  State<ResetFeaturePresentumItemsStorage> createState() =>
      _ResetFeaturePresentumItemsStorageState();
}

class _ResetFeaturePresentumItemsStorageState
    extends State<ResetFeaturePresentumItemsStorage> {
  late final Presentum<FeatureItem, AppSurface, AppVariant> _presentum;
  late final PresentumStateObserver<FeatureItem, AppSurface, AppVariant>
  _observer;

  List<FeatureItem> _items = [];

  @override
  void initState() {
    super.initState();
    _presentum = context.presentum<FeatureItem, AppSurface, AppVariant>();
    _observer = context
        .presentum<FeatureItem, AppSurface, AppVariant>()
        .observer;

    // Initial state evaluation.
    _onStateChange();

    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final candidates = _presentum.config.engine.currentCandidates;
    _items = candidates;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deps = Dependencies.of(context);
    final catalog = deps.featureCatalog;
    final l10n = context.l10n;

    return ExpansionTile(
      title: Text(l10n.resetFeaturePresentumItemsStorageTitle),
      subtitle: Text(l10n.resetFeaturePresentumItemsStorageSubtitle),
      initiallyExpanded: false,
      children: [
        for (final item in _items)
          ListenableBuilder(
            listenable: catalog,
            builder: (context, child) {
              return ListTile(
                title: Text(
                  l10n.resetFeaturePresentumItemSurfaceVariant(
                    item.surface.name,
                    item.variant.name,
                  ),
                ),
                subtitle: Text(l10n.resetFeaturePresentumItemId(item.id)),
                onTap: () {
                  _presentum.config.storage.clearItem(
                    item.id,
                    surface: item.surface,
                    variant: item.variant,
                  );

                  // Force state update and all guards to re-evaluate.
                  _presentum.config.engine.setCandidates(
                    (_, candidates) => candidates,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
