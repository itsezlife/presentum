import 'package:app_ui/app_ui.dart';
import 'package:boxy/boxy.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class NewYearBanner extends StatelessWidget {
  const NewYearBanner({super.key, this.padding});

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) =>
      PresentumOutlet<FeatureItem, AppSurface, AppVariant>(
        surface: AppSurface.homeHeader,
        builder: (context, item) {
          const child = RepaintBoundary(child: _NewYearBannerContent());
          if (padding case final padding?)
            return Padding(padding: padding, child: child);
          return child;
        },
      );
}

class _NewYearBannerContent extends StatefulWidget {
  // ignore: unused_element_parameter
  const _NewYearBannerContent({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  State<_NewYearBannerContent> createState() => _NewYearBannerContentState();
}

class _NewYearBannerContentState extends State<_NewYearBannerContent> {
  final ValueNotifier<bool> _showYearBadgeNotifier = ValueNotifier(true);

  @override
  void dispose() {
    _showYearBadgeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = context.presentumItem<FeatureItem, AppSurface, AppVariant>();
    final isDismissible = item.option.isDismissible;

    return SizedBox(
      height: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomBoxy(
          delegate: _NewYearBannerDelegate(
            showYearBadgeNotifier: _showYearBadgeNotifier,
            isDismissible: isDismissible,
          ),
          children: [
            const BoxyId(id: #background, child: _BannerBackground()),
            BoxyId(
              id: #content,
              child: _BannerContent(showYearBadge: _showYearBadgeNotifier),
            ),
            const BoxyId(id: #yearBadge, child: _YearBadge()),
            if (isDismissible)
              const BoxyId(id: #closeButton, child: _CloseButton()),
          ],
        ),
      ),
    );
  }
}

class _NewYearBannerDelegate extends BoxyDelegate {
  _NewYearBannerDelegate({
    required this.showYearBadgeNotifier,
    required this.isDismissible,
  });

  final ValueNotifier<bool> showYearBadgeNotifier;
  final bool isDismissible;

  @override
  Size layout() {
    final background = getChild(#background);
    final content = getChild(#content);
    final yearBadge = getChild(#yearBadge);
    final closeButton = isDismissible ? getChild(#closeButton) : null;

    final full = constraints.biggest;

    // Layout background to fill available space
    background
      ..layout(constraints)
      ..position(Offset.zero);

    const horizontalPadding = AppSpacing.lg;
    const verticalPadding = AppSpacing.lg;
    const minGapBetweenContentAndYear = AppSpacing.lg;

    // Layout content on the left
    final contentSize = content.layout(
      constraints.deflate(
        const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
      ),
    );
    content.position(const Offset(horizontalPadding, verticalPadding));

    // Layout year badge
    final yearBadgeSize = yearBadge.layout(constraints.loosen());

    // Calculate if year badge would intersect with content
    final contentRight = horizontalPadding + contentSize.width;
    final yearBadgeLeft = full.width - horizontalPadding - yearBadgeSize.width;
    final hasEnoughSpace =
        yearBadgeLeft - contentRight >= minGapBetweenContentAndYear;

    // Notify the content widget about year badge visibility
    // Schedule this for after the current frame to avoid updating during layout
    if (showYearBadgeNotifier.value != hasEnoughSpace) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showYearBadgeNotifier.value = hasEnoughSpace;
      });
    }

    if (hasEnoughSpace) {
      // Year text aligned vertically with card center, on the right
      final yearBadgeDy = (full.height - yearBadgeSize.height) / 2;
      yearBadge.position(Offset(yearBadgeLeft, yearBadgeDy));
    } else {
      // Hide year badge by positioning it offscreen
      yearBadge.position(Offset(-yearBadgeSize.width, 0));
    }

    // Close button in top-right corner
    if (closeButton case final closeButton?) {
      final closeButtonSize = closeButton.layout(constraints.loosen());
      closeButton.position(
        Offset(
          full.width - (horizontalPadding * 0.3) - closeButtonSize.width,
          verticalPadding * 0.3,
        ),
      );
    }

    return full;
  }

  @override
  bool shouldRelayout(covariant _NewYearBannerDelegate oldDelegate) => false;
}

class _BannerBackground extends StatelessWidget {
  const _BannerBackground();

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F2FE), // Light sky blue
            Color(0xFFBAE6FD), // Cool blue
            Color(0xFF7DD3FC), // Bright icy blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.showYearBadge});

  final ValueNotifier<bool> showYearBadge;

  static final double _minWidthForIcon = ScreenSize.tablet.min;
  static final double _minWidthForLargeSubtitle = ScreenSize.tablet.min;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    final item = context.presentumItem<FeatureItem, AppSurface, AppVariant>();
    final year = item.metadata['year'] as String?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showIcon = constraints.maxWidth > _minWidthForIcon;
        final showLargeSubtitle =
            constraints.maxWidth > _minWidthForLargeSubtitle;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DD3FC).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 32,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: showYearBadge,
                    builder: (context, isYearBadgeVisible, child) => Text(
                      isYearBadgeVisible || year == null
                          ? l10n.newYearBannerTitle
                          : l10n.newYearBannerTitleWithYear(year),
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        fontWeight: AppFontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    showLargeSubtitle
                        ? l10n.newYearBannerSubtitleLargeVersion
                        : l10n.newYearBannerSubtitleSmallVersion,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YearBadge extends StatelessWidget {
  const _YearBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final item = context.presentumItem<FeatureItem, AppSurface, AppVariant>();
    final year = item.metadata['year'] as String?;
    if (year == null) return const SizedBox.shrink();

    return Text(
      year,
      style: textTheme.displayMedium?.copyWith(
        color: const Color(0xFF0284C7),
        fontWeight: AppFontWeight.extraBold,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      final item = context.presentumItem<FeatureItem, AppSurface, AppVariant>();
      context.presentum<FeatureItem, AppSurface, AppVariant>().markDismissed(
        item,
      );
    },
    child: const Icon(Icons.close, size: 20, color: Color(0xFF2D3748)),
  );
}
