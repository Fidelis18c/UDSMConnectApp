import 'package:flutter/material.dart';

/// Skeleton shimmer loader for event cards in the 2-column grid
class EventCardSkeleton extends StatefulWidget {
  const EventCardSkeleton({Key? key}) : super(key: key);

  @override
  State<EventCardSkeleton> createState() => _EventCardSkeletonState();
}

class _EventCardSkeletonState extends State<EventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image placeholder
              Expanded(
                flex: 6,
                child: Container(
                  color: Color.lerp(
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEAEAEA),
                    isDark ? const Color(0xFF2E2E2E) : const Color(0xFFD6D6D6),
                    _animation.value,
                  ),
                ),
              ),
              // Text placeholders
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _skeletonBar(double.infinity, _animation.value, isDark),
                      _skeletonBar(double.infinity, _animation.value, isDark),
                      _skeletonBar(100, _animation.value, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBar(double width, double animVal, bool isDark) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Color.lerp(
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCFCFCF),
          animVal,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Skeleton for the horizontal past events row
class PastEventCardSkeleton extends StatefulWidget {
  const PastEventCardSkeleton({Key? key}) : super(key: key);

  @override
  State<PastEventCardSkeleton> createState() => _PastEventCardSkeletonState();
}

class _PastEventCardSkeletonState extends State<PastEventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Color.lerp(
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEAEAEA),
                    isDark ? const Color(0xFF2E2E2E) : const Color(0xFFD6D6D6),
                    _animation.value,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBar(80, _animation.value, isDark),
                    const SizedBox(height: 6),
                    _skeletonBar(double.infinity, _animation.value, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBar(double width, double animVal, bool isDark) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Color.lerp(
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCFCFCF),
          animVal,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Skeleton for category grid cards
class CategoryCardSkeleton extends StatefulWidget {
  const CategoryCardSkeleton({Key? key}) : super(key: key);

  @override
  State<CategoryCardSkeleton> createState() => _CategoryCardSkeletonState();
}

class _CategoryCardSkeletonState extends State<CategoryCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor = Color.lerp(
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCFCFCF),
          _animation.value,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
