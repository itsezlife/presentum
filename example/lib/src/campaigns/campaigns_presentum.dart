import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/campaigns_presentum_state_mixin.dart';
import 'package:flutter/material.dart';

/// {@template campaigns_presentum}
/// Wrapper that wires the campaigns presentum + popup host.
/// {@endtemplate}
class CampaignsPresentum extends StatefulWidget {
  /// {@macro campaigns_presentum}
  const CampaignsPresentum({required this.child, super.key});

  /// The child widget to display.
  final Widget child;

  @override
  State<CampaignsPresentum> createState() => _CampaignsPresentumState();
}

class _CampaignsPresentumState extends State<CampaignsPresentum>
    with CampaignsPresentumStateMixin {
  @override
  Widget build(BuildContext context) => campaignPresentum.config.engine.build(
    context,
    CampaignPopupHost(child: widget.child),
  );
}
