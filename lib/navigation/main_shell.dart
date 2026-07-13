import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/providers/scroll_visibility_provider.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({Key? key, required this.navigationShell}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _navVisible = true;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 4 && _navVisible) {
        setState(() => _navVisible = false);
        ref.read(scrollVisibilityProvider.notifier).set(false);
      } else if (delta < -4 && !_navVisible) {
        setState(() => _navVisible = true);
        ref.read(scrollVisibilityProvider.notifier).set(true);
      }
    }
    return false;
  }

  void _onTap(BuildContext context, int index) {
    // Always show nav when switching tabs
    if (!_navVisible) {
      setState(() => _navVisible = true);
      ref.read(scrollVisibilityProvider.notifier).set(true);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 76.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: _navVisible ? navBarHeight + bottomPadding : 0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 72,
              // Twitter-style: near-black in dark mode, white in light mode.
              backgroundColor: isDark ? const Color(0xFF070707) : Colors.white,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black38,
              elevation: 6,
              indicatorColor: Colors.transparent,
              indicatorShape: const RoundedRectangleBorder(),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primary.withValues(alpha: 0.1);
                }
                return Colors.transparent;
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                final color = isDark
                    ? (selected ? AppColors.primary : AppColors.textHint)
                    : (selected ? Colors.black : Colors.black54);
                return IconThemeData(
                  color: color,
                  size: selected ? 26 : 24,
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                final color = isDark
                    ? (selected ? AppColors.primary : AppColors.textHint)
                    : (selected ? Colors.black : Colors.black54);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.1,
                  color: color,
                );
              }),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: NavigationBar(
                indicatorColor: Colors.transparent,
                indicatorShape: const RoundedRectangleBorder(),
                animationDuration: const Duration(milliseconds: 260),
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (i) => _onTap(context, i),
                destinations: [
                  NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.newspaper, size: 24),
                    selectedIcon: PhosphorIcon(PhosphorIconsBold.newspaper, size: 26),
                    label: 'News',
                  ),
                  NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.chatsTeardrop, size: 24),
                    selectedIcon: PhosphorIcon(PhosphorIconsBold.chatsTeardrop, size: 26),
                    label: 'Feedback',
                  ),
                  NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.sparkle, size: 24),
                    selectedIcon: PhosphorIcon(PhosphorIconsBold.sparkle, size: 26),
                    label: 'For you',
                  ),
                  NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.calendarDot, size: 24),
                    selectedIcon: PhosphorIcon(PhosphorIconsBold.calendarDot, size: 26),
                    label: 'Events',
                  ),
                  NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.package, size: 24),
                    selectedIcon: PhosphorIcon(PhosphorIconsBold.package, size: 26),
                    label: 'Lost & Found',
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
