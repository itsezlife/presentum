import 'package:example/src/shop/presentum/recommendation_presentum_state_mixin.dart';
import 'package:flutter/material.dart';

/// {@template recommendation_presentum}
/// RecommendationPresentum is a widget that initializes
/// the recommendation presentum and provides it to the widget tree.
/// {@endtemplate}
class RecommendationPresentum extends StatefulWidget {
  /// {@macro recommendation_presentum}
  const RecommendationPresentum({required this.child, super.key});

  final Widget child;

  @override
  State<RecommendationPresentum> createState() =>
      _RecommendationPresentumStateMixin();
}

class _RecommendationPresentumStateMixin extends State<RecommendationPresentum>
    with RecommendationPresentumStateMixin {
  @override
  Widget build(BuildContext context) =>
      recommendationPresentum.config.engine.build(context, widget.child);
}
