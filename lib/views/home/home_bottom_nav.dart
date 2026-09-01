import 'package:flutter/material.dart';

typedef NavDestination = ({IconData icon, String label});

/// Bottom navigation bar that continuously interpolates its indicator
/// and icon colors based on a [PageController]'s fractional page value.
class AnimatedBottomNav extends StatelessWidget {
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;

  const AnimatedBottomNav({
    super.key,
    required this.pageController,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      elevation: 3,
      surfaceTintColor: cs.surfaceTint,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: AnimatedBuilder(
            animation: pageController,
            builder: (context, _) {
              final page = pageController.hasClients
                  ? (pageController.page ?? currentIndex.toDouble())
                  : currentIndex.toDouble();
              return Row(
                children: List.generate(destinations.length, (i) {
                  final d = destinations[i];
                  final distance = (page - i).abs().clamp(0.0, 1.0);
                  final t = 1.0 - distance;
                  final iconColor = Color.lerp(
                    cs.onSurfaceVariant,
                    cs.onSecondaryContainer,
                    t,
                  )!;
                  final labelColor = Color.lerp(
                    cs.onSurfaceVariant,
                    cs.onSurface,
                    t,
                  )!;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedIndicator(
                            opacity: t,
                            color: cs.secondaryContainer,
                            child: Icon(d.icon, color: iconColor, size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: labelColor,
                              fontWeight: t > 0.5
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedIndicator extends StatelessWidget {
  final double opacity;
  final Color color;
  final Widget child;

  const _AnimatedIndicator({
    required this.opacity,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
