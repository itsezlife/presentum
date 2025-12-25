import 'package:example/src/feature/presentum/presentum_state_mixin.dart';
import 'package:flutter/material.dart';

class FeaturePresentum extends StatefulWidget {
  const FeaturePresentum({required this.child, super.key});

  final Widget child;

  @override
  State<FeaturePresentum> createState() => _FeaturePresentumState();
}

class _FeaturePresentumState extends State<FeaturePresentum>
    with FeaturePresentumStateMixin {
  @override
  Widget build(BuildContext context) {
    return featurePresentum.config.engine.build(context, widget.child);
  }
}
