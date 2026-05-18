import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/attendee.dart';
import '../../../../core/widgets/avatar_initials.dart';
import '../providers/events_provider.dart';

/// Shows the list of registered attendees in a draggable bottom sheet.
/// Only call this for users with organizer/admin access; the backend enforces it.
class AttendeesBottomSheet extends ConsumerWidget {
  final String eventId;
  final int goingCount;

  const AttendeesBottomSheet({
    super.key,
    required this.eventId,
    required this.goingCount,
  });

  static void show(BuildContext context, String eventId, int goingCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendeesBottomSheet(
        eventId: eventId,
        goingCount: goingCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendees',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$goingCount registered',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF222222), height: 1),

              // List
              Expanded(
                child: attendeesAsync.when(
                  loading: () => _buildSkeletons(),
                  error: (err, _) => _buildError(err.toString()),
                  data: (attendees) => attendees.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: attendees.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0xFF1E1E1E),
                            height: 1,
                            indent: 72,
                          ),
                          itemBuilder: (_, index) =>
                              _AttendeeRow(attendee: attendees[index]),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (_, __) => const _AttendeeSkeleton(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF666666), size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load attendees',
              style: GoogleFonts.inter(
                color: const Color(0xFF888888),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF555555),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: Color(0xFF444444), size: 56),
          const SizedBox(height: 12),
          Text(
            'No one has registered yet',
            style: GoogleFonts.inter(
              color: const Color(0xFF666666),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share the event to get people interested!',
            style: GoogleFonts.inter(
              color: const Color(0xFF444444),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final Attendee attendee;
  const _AttendeeRow({required this.attendee});

  @override
  Widget build(BuildContext context) {
    final initials = attendee.userName.isNotEmpty
        ? attendee.userName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          AvatarInitials(initials: initials, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.userName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  attendee.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A1B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Going',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeSkeleton extends StatefulWidget {
  const _AttendeeSkeleton();

  @override
  State<_AttendeeSkeleton> createState() => _AttendeeSkeletonState();
}

class _AttendeeSkeletonState extends State<_AttendeeSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c = Color.lerp(
          const Color(0xFF1E1E1E),
          const Color(0xFF2E2E2E),
          _anim.value,
        )!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: c),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 180,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
