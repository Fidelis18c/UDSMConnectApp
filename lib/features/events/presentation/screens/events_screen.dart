import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/events/presentation/providers/events_provider.dart';
import 'package:udsm_connect/core/models/event.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/past_event_card.dart';
import '../widgets/event_category_grid_card.dart';
import '../widgets/event_skeleton.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.read(searchQueryProvider.notifier).set('');
    _searchController.clear();
    await ref.read(eventsProvider.notifier).refresh();
    ref.invalidate(pastEventsProvider);
    ref.invalidate(eventCategoriesProvider);
  }

  void _navigateToDetail(Event event) {
    context.pushNamed(
      RouteNames.eventDetail,
      pathParameters: {'id': event.id},
      extra: event,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isStudent = user?.isStudent ?? false;
    final selectedCategoryId = ref.watch(selectedEventCategoryIdProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: isStudent
            ? null
            : FloatingActionButton(
                onPressed: () => context.pushNamed(RouteNames.createEvent),
                backgroundColor: const Color(0xFF1565C0),
                child: const Icon(Icons.add, color: Colors.white),
              ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF1565C0),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Events',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // balance back button
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
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).set(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search events',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF666666),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF666666),
                          size: 22,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (ctx, val, _) {
                            if (val.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF666666),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).set('');
                              },
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Categories Grid ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _CategoriesSection(selectedId: selectedCategoryId),
              ),

              // ── Past Events ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _PastEventsSection(onTap: _navigateToDetail),
              ),

              // ── Upcoming Events header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                  child: Text(
                    'Upcoming events',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ── Upcoming Events 2-col Grid ────────────────────────────
              _UpcomingEventsGrid(onTap: _navigateToDetail),

              // bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories Section
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesSection extends ConsumerWidget {
  final String? selectedId;

  const _CategoriesSection({required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(eventCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: categoriesAsync.when(
        loading: () => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.0,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const CategoryCardSkeleton(),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) {
          if (categories.isEmpty) return const SizedBox.shrink();

          // Prepend an "All" entry
          final allCategory = EventCategory(id: '', name: 'All');
          final displayList = [allCategory, ...categories];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.0,
            ),
            itemCount: displayList.length,
            itemBuilder: (_, index) {
              final cat = displayList[index];
              final isSelected = cat.id.isEmpty
                  ? selectedId == null
                  : selectedId == cat.id;

              return EventCategoryGridCard(
                category: cat,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedEventCategoryIdProvider.notifier).set(
                        cat.id.isEmpty ? null : cat.id,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Past Events Section
// ─────────────────────────────────────────────────────────────────────────────

class _PastEventsSection extends ConsumerWidget {
  final void Function(Event) onTap;

  const _PastEventsSection({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAsync = ref.watch(pastEventsProvider);

    return pastAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
            child: Text(
              'Past events',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              itemBuilder: (_, __) => const PastEventCardSkeleton(),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
              child: Text(
                'Past events',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (_, index) => PastEventCard(
                  event: events[index],
                  onTap: () => onTap(events[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming Events 2-Column Grid (Sliver)
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingEventsGrid extends ConsumerWidget {
  final void Function(Event) onTap;

  const _UpcomingEventsGrid({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredUpcomingEventsProvider);

    return eventsAsync.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const EventCardSkeleton(),
            childCount: 6,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Failed to load events.\nPull down to retry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_busy_outlined,
                      color: Color(0xFF444444),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming events',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF666666),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later or explore\na different category.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF444444),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, index) => UpcomingEventCard(
                event: events[index],
                onTap: () => onTap(events[index]),
              ),
              childCount: events.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
          ),
        );
      },
    );
  }
}
