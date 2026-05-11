import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({Key? key, required this.navigationShell}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          backgroundColor: const Color(0xFF070707),
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
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.textHint,
              size: selected ? 26 : 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.2,
              height: 1.1,
              color: selected ? AppColors.primary : AppColors.textHint,
            );
          }),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: NavigationBar(
            indicatorColor: Colors.transparent,
            indicatorShape: const RoundedRectangleBorder(),
            animationDuration: const Duration(milliseconds: 260),
            selectedIndex: navigationShell.currentIndex,
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
    );
  }
}
