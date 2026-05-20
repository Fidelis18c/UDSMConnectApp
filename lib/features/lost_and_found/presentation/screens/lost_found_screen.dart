import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import '../providers/lost_found_provider.dart';
import '../widgets/lost_found_card.dart';

class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredLostFoundProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: const _ExpandableFab(),
        body: RefreshIndicator(
          onRefresh: () => ref.read(lostFoundItemsProvider.notifier).refresh(),
          color: AppColors.primary,
          backgroundColor: const Color(0xFF1A1A1A),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Lost & Found',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Reuniting people with belongings',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search Bar ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      onChanged: (val) =>
                          ref.read(lfSearchQueryProvider.notifier).set(val),
                      decoration: InputDecoration(
                        hintText: 'Search Post',
                        hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF666666), fontSize: 14),
                        prefixIcon: const Icon(
                            Icons.search_rounded, color: Color(0xFF666666), size: 22),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (ctx, val, _) {
                            if (val.text.isEmpty) return const SizedBox.shrink();
                            return IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF666666), size: 20),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(lfSearchQueryProvider.notifier).set('');
                              },
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Type Filters ─────────────────────────────────────────
              const SliverToBoxAdapter(child: _TypeFilters()),

              // ── Title ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'Recent Posts',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ── Grid ─────────────────────────────────────────────────
              itemsAsync.when(
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Failed to load items',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          message: 'No items found',
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return LostFoundCard(
                            item: item,
                            onTap: () {
                              context.pushNamed(
                                RouteNames.lostFoundDetail,
                                pathParameters: {'id': item.id},
                                extra: item,
                              );
                            },
                          );
                        },
                        childCount: items.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65, // matches image proportions
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters
// ─────────────────────────────────────────────────────────────────────────────

class _TypeFilters extends ConsumerWidget {
  const _TypeFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(typeFilterProvider);

    Widget buildChip(String label, String? value) {
      final selected = type == value;
      return GestureDetector(
        onTap: () => ref.read(typeFilterProvider.notifier).set(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          buildChip('All', null),
          const SizedBox(width: 8),
          buildChip('Lost', 'LOST'),
          const SizedBox(width: 8),
          buildChip('Found', 'FOUND'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Expandable FAB
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableFab extends StatefulWidget {
  const _ExpandableFab();

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(
        parent: _controller, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _create(String type) {
    _toggle();
    context.pushNamed(
      RouteNames.createLostFound,
      extra: <String, dynamic>{'type': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          // Found Option
          FadeTransition(
            opacity: _expandAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Report Found',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'fab_found',
                    onPressed: () => _create('FOUND'),
                    backgroundColor: const Color(0xFF2E7D32),
                    child: const Icon(Icons.location_on, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lost Option
          FadeTransition(
            opacity: _expandAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Report Lost',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'fab_lost',
                    onPressed: () => _create('LOST'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Main FAB
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0, // 45 degrees
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
