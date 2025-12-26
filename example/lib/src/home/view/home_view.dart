import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/feature/feature_presentum.dart';
import 'package:example/src/home/widgets/home_tabs_mixin.dart';
import 'package:flutter/material.dart';

/// {@template home_view}
/// HomeView widget.
/// {@endtemplate}
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeTabsMixin {
  @override
  AppTab get tab => const HomeAppTab();

  @override
  Widget build(BuildContext context) =>
      FeaturePresentum(child: buildTabs(context));
}
