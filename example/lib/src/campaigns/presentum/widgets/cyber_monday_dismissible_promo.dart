// ignore_for_file: cascade_invocations

import 'package:app_ui/app_ui.dart';
import 'package:boxy/boxy.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared/shared.dart';

class CyberMondayDismissiblePromo extends StatefulWidget {
  const CyberMondayDismissiblePromo({super.key});

  @override
  State<CyberMondayDismissiblePromo> createState() =>
      _CyberMondayPromoContentState();
}

class _CyberMondayPromoContentState extends State<CyberMondayDismissiblePromo>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _showDiscountBadgeNotifier = ValueNotifier(true);
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _showDiscountBadgeNotifier.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = context.campaignItem;
    final isDismissible = item.option.isDismissible;

    return SizedBox(
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomBoxy(
          delegate: _CyberMondayBannerDelegate(
            showDiscountBadgeNotifier: _showDiscountBadgeNotifier,
            isDismissible: isDismissible,
          ),
          children: [
            BoxyId(
              id: #background,
              child: _BannerBackground(pulseController: _pulseController),
            ),
            BoxyId(
              id: #content,
              child: _BannerContent(
                showDiscountBadge: _showDiscountBadgeNotifier,
              ),
            ),
            const BoxyId(id: #discountBadge, child: _DiscountBadge()),
            if (isDismissible)
              const BoxyId(id: #closeButton, child: _CloseButton()),
          ],
        ),
      ),
    );
  }
}

class _CyberMondayBannerDelegate extends BoxyDelegate {
  _CyberMondayBannerDelegate({
    required this.showDiscountBadgeNotifier,
    required this.isDismissible,
  });

  final ValueNotifier<bool> showDiscountBadgeNotifier;
  final bool isDismissible;

  @override
  Size layout() {
    final background = getChild(#background);
    final content = getChild(#content);
    final discountBadge = getChild(#discountBadge);
    final closeButton = isDismissible ? getChild(#closeButton) : null;

    final full = constraints.biggest;

    // Layout background to fill available space
    background
      ..layout(constraints)
      ..position(Offset.zero);

    const horizontalPadding = AppSpacing.xlg;
    const verticalPadding = AppSpacing.lg;
    const minGapBetweenContentAndBadge = AppSpacing.xlg;

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

    // Layout discount badge
    final discountBadgeSize = discountBadge.layout(constraints.loosen());

    // Calculate if discount badge would intersect with content
    final contentRight = horizontalPadding + contentSize.width;
    final discountBadgeLeft =
        full.width - horizontalPadding - discountBadgeSize.width;
    final hasEnoughSpace =
        discountBadgeLeft - contentRight >= minGapBetweenContentAndBadge;

    // Notify the content widget about discount badge visibility
    if (showDiscountBadgeNotifier.value != hasEnoughSpace) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDiscountBadgeNotifier.value = hasEnoughSpace;
      });
    }

    if (hasEnoughSpace) {
      // Discount badge aligned vertically with card center, on the right
      final discountBadgeDy = (full.height - discountBadgeSize.height) / 2;
      discountBadge.position(Offset(discountBadgeLeft, discountBadgeDy));
    } else {
      // Hide discount badge by positioning it offscreen
      discountBadge.position(Offset(-discountBadgeSize.width, 0));
    }

    // Close button in top-right corner
    if (closeButton case final closeButton?) {
      final closeButtonSize = closeButton.layout(constraints.loosen());
      closeButton.position(
        Offset(
          full.width - (horizontalPadding * 0.4) - closeButtonSize.width,
          verticalPadding * 0.4,
        ),
      );
    }

    return full;
  }

  @override
  bool shouldRelayout(covariant _CyberMondayBannerDelegate oldDelegate) =>
      false;
}

class _BannerBackground extends StatelessWidget {
  const _BannerBackground({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulseController,
    builder: (context, child) {
      final pulseValue = pulseController.value;
      return SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F0F23), // Deep dark blue
                const Color(0xFF1A0B2E), // Dark purple
                Color.lerp(
                  const Color(0xFF2D1B4E),
                  const Color(0xFF3D2B5E),
                  pulseValue,
                )!, // Purple with pulse
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00F5FF,
                ).withValues(alpha: 0.2 + (pulseValue * 0.1)),
                blurRadius: 16 + (pulseValue * 8),
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(
                  0xFFFF006E,
                ).withValues(alpha: 0.15 + (pulseValue * 0.1)),
                blurRadius: 20 + (pulseValue * 10),
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Circuit board pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _CircuitPatternPainter(
                    opacity: 0.1 + (pulseValue * 0.05),
                  ),
                ),
              ),
              // Gradient overlay for depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF).withValues(alpha: 0.05),
                      Colors.transparent,
                      const Color(0xFFFF006E).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CircuitPatternPainter extends CustomPainter {
  _CircuitPatternPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw some circuit-like lines
    final path = Path();

    // Horizontal lines
    path
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..moveTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.6);

    // Vertical lines
    path
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.2, size.height * 0.4)
      ..moveTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height);

    canvas.drawPath(path, paint);

    // Draw circuit nodes
    final nodePaint = Paint()
      ..color = const Color(0xFFFF006E).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(Offset(size.width * 0.2, size.height * 0.3), 3, nodePaint)
      ..drawCircle(Offset(size.width * 0.5, size.height * 0.6), 3, nodePaint)
      ..drawCircle(Offset(size.width * 0.7, size.height * 0.6), 3, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _CircuitPatternPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.showDiscountBadge});

  final ValueNotifier<bool> showDiscountBadge;

  static final double _minWidthForLargeSubtitle = ScreenSize.tablet.min;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final item = context.campaignItem;
    final discount = item.metadata['discount'] as Map<String, dynamic>?;
    final maxDiscount = switch (discount?['max_discount']) {
      final int maxDiscount => maxDiscount.toString(),
      final String maxDiscount => maxDiscount,
      _ => null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLargeSubtitle =
            constraints.maxWidth > _minWidthForLargeSubtitle;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: showDiscountBadge,
                    builder: (context, isBadgeVisible, child) => ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00F5FF), Color(0xFFFF006E)],
                      ).createShader(bounds),
                      child: Text(
                        isBadgeVisible || maxDiscount == null
                            ? 'Cyber Monday'
                            : 'Cyber Monday - $maxDiscount OFF',
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: AppFontWeight.extraBold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    showLargeSubtitle
                        ? 'Limited time offer - Save big on all products!'
                        : 'Limited time offer!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF00F5FF).withValues(alpha: 0.9),
                      height: 1.3,
                      fontWeight: AppFontWeight.medium,
                    ),
                    maxLines: 2,
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

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final item = context.campaignItem;
    final discount = item.metadata['discount'] as Map<String, dynamic>?;
    final maxDiscount = switch (discount?['max_discount']) {
      final int maxDiscount => maxDiscount.toString(),
      final String maxDiscount => maxDiscount,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF006E), Color(0xFFFF3D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006E).withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: maxDiscount == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$maxDiscount%',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeight.extraBold,
                    height: 1,
                    fontSize: 40,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Text(
                  'OFF',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      final item = context.campaignItem;
      context.campaignsPresentum.markDismissed(item);
    },
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close, size: 18, color: Color(0xFF00F5FF)),
    ),
  );
}
