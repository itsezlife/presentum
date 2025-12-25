import 'package:app_ui/app_ui.dart';
import 'package:boxy/boxy.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class NewYearBanner extends StatelessWidget {
  const NewYearBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return PresentumOutlet<FeatureItem, AppSurface, AppVariant>(
      surface: AppSurface.homeHeader,
      builder: (context, item) {
        return _NewYearBannerContent(item: item);
      },
    );
  }
}

class _NewYearBannerContent extends StatefulWidget {
  const _NewYearBannerContent({required this.item});

  final FeatureItem item;

  @override
  State<_NewYearBannerContent> createState() => _NewYearBannerContentState();
}

class _NewYearBannerContentState extends State<_NewYearBannerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  late Animation<Offset> _slideAnimation;
  final ValueNotifier<bool> _showYearBadgeNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1750),
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    );

    _sizeAnimation = curvedAnimation;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _showYearBadgeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomBoxy(
                delegate: _NewYearBannerDelegate(
                  showYearBadgeNotifier: _showYearBadgeNotifier,
                ),
                children: [
                  const BoxyId(id: #background, child: _BannerBackground()),
                  BoxyId(
                    id: #content,
                    child: _BannerContent(
                      item: widget.item,
                      showYearBadge: _showYearBadgeNotifier,
                    ),
                  ),
                  BoxyId(
                    id: #yearBadge,
                    child: _YearBadge(item: widget.item),
                  ),
                  BoxyId(
                    id: #closeButton,
                    child: _CloseButton(item: widget.item),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewYearBannerDelegate extends BoxyDelegate {
  _NewYearBannerDelegate({required this.showYearBadgeNotifier});

  final ValueNotifier<bool> showYearBadgeNotifier;

  @override
  Size layout() {
    final background = getChild(#background);
    final content = getChild(#content);
    final yearBadge = getChild(#yearBadge);
    final closeButton = getChild(#closeButton);

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
    final closeButtonSize = closeButton.layout(constraints.loosen());
    closeButton.position(
      Offset(
        full.width - (horizontalPadding * 0.3) - closeButtonSize.width,
        verticalPadding * 0.3,
      ),
    );

    return full;
  }

  @override
  bool shouldRelayout(covariant _NewYearBannerDelegate oldDelegate) => false;
}

class _BannerBackground extends StatelessWidget {
  const _BannerBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
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
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.item, required this.showYearBadge});

  final FeatureItem item;
  final ValueNotifier<bool> showYearBadge;

  static const double _minWidthForIcon = 500.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    final year = item.metadata['year'] as String? ?? '2025';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showIcon = constraints.maxWidth > _minWidthForIcon;

        return ValueListenableBuilder<bool>(
          valueListenable: showYearBadge,
          builder: (context, isYearBadgeVisible, _) {
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
                      Text(
                        isYearBadgeVisible
                            ? l10n.newYearBannerTitle
                            : l10n.newYearBannerTitleWithYear(year),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.newYearBannerSubtitle,
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
      },
    );
  }
}

class _YearBadge extends StatelessWidget {
  const _YearBadge({required this.item});

  final FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final year = item.metadata['year'] as String? ?? '2025';

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
  const _CloseButton({required this.item});

  final FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.presentum<FeatureItem, AppSurface, AppVariant>().markDismissed(
          item,
        );
      },
      child: const Icon(Icons.close, size: 20, color: Color(0xFF2D3748)),
    );
  }
}
