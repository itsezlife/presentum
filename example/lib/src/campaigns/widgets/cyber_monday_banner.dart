import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class CyberMondayBanner extends StatelessWidget {
  const CyberMondayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;

    const bannerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF020B12), // darker top-left corner
        Color(0xFF006871), // bright center
        Color(0xFF006871), // bright center
        Color(0xFF020B12), // darker bottom-right corner
      ],
      stops: [0.0, 0.2, 0.8, 1.0],
    );

    const buttonGradient = LinearGradient(
      colors: [
        Color.fromRGBO(70, 144, 254, 1),
        Color.fromRGBO(91, 249, 213, 1),
      ],
      stops: [.0, .5],
    );

    final titleStyle = textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontSize: 18,
      fontWeight: AppFontWeight.medium,
    );

    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      color: Colors.black,
      fontWeight: AppFontWeight.regular,
    );

    // return Tappable.faded(
    return GestureDetector(
      onTap: () {
        // context.intentsNavigator.pushNamed(Routes.subscriptions.name);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: bannerGradient,
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.md)),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: buttonGradient.colors,
                    stops: const [.0, .3],
                  ).createShader(bounds),
                  child: Text('Cyber Monday', style: titleStyle),
                ),
              ),
              const SizedBox(width: AppSpacing.xlg),
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: buttonGradient,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppSpacing.md),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text('Explore Offers', style: buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
