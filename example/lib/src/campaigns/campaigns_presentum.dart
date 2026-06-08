import 'dart:async';

import 'package:control/control.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/campaigns_storage.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';

/// {@template campaigns_presentum}
/// Wrapper that wires [CampaignsController], [ControllerScope], and popup host.
/// {@endtemplate}
class CampaignsPresentum extends StatefulWidget {
  /// {@macro campaigns_presentum}
  const CampaignsPresentum({required this.child, super.key});

  /// The child widget to display.
  final Widget child;

  @override
  State<CampaignsPresentum> createState() => _CampaignsPresentumState();
}

class _CampaignsPresentumState extends State<CampaignsPresentum> {
  late final CampaignsController _controller;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    final storage = CampaignPersistentStorage(prefs: deps.sharedPreferences);
    final eligibility = EligibilityResolver<HasMetadata>(
      extractors: const [
        TimeRangeExtractor(),
        ConstantExtractor(metadataKey: 'is_active'),
        AnyOfExtractor(
          nestedExtractors: [
            TimeRangeExtractor(),
            ConstantExtractor(metadataKey: 'is_active'),
          ],
        ),
      ],
    );

    _controller = CampaignsController(
      storage: storage,
      eligibility: eligibility,
      remoteConfigRepository: deps.remoteConfigRepository,
      userRepository: deps.userRepository,
    );

    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ControllerScope.value(
    _controller,
    child: ValueListenableBuilder<CampaignSlots>(
      valueListenable: _controller.select((state) => state.slots),
      builder: (context, slots, child) => PresentumPopupHost(
        slots: slots,
        surface: CampaignSurface.popup,
        ignoreDuplicates: true,
        onShown: _controller.markShown,
        onMarkDismissed: _controller.markDismissed,
        present: (entry) => CampaignPopupPresenter.present(context, entry),
        child: child!,
      ),
      child: widget.child,
    ),
  );
}
