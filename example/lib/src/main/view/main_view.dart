import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/feature/widgets/snow_outlet.dart';
import 'package:example/src/main/widgets/new_year_banner.dart';
import 'package:flutter/material.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SnowOutlet(
        flakeCount: 500,
        minSpeed: 10,
        maxSpeed: 40,
        minRadius: .25,
        maxRadius: 2.5,
        windStrength: 25,
        swayStrength: 30,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Main View'),
              pinned: true,
              floating: true,
              snap: true,
            ),
            SliverPadding(
              padding: ScaffoldPadding.of(
                context,
              ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
              sliver: SliverList.list(children: const [NewYearBanner()]),
            ),
          ],
        ),
      ),
    ),
  );
}
