import 'package:control/control.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/shop/controller/recommendation_controller.dart';
import 'package:flutter/material.dart';

class RecommendationPresentum extends StatefulWidget {
  const RecommendationPresentum({required this.child, super.key});

  final Widget child;

  @override
  State<RecommendationPresentum> createState() =>
      _RecommendationPresentumState();
}

class _RecommendationPresentumState extends State<RecommendationPresentum> {
  late final RecommendationController _controller;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _controller = RecommendationController(
      storage: PersistentPresentumStorage(prefs: deps.sharedPreferences),
      store: deps.recommendationStore,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ControllerScope.value(_controller, child: widget.child);
}
