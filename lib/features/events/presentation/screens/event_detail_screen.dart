import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:udsm_connect/core/models/event.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_initials.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/attendees_bottom_sheet.dart';
import '../widgets/calendar_dialog.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late int _goingCount;
  bool _isRsvpLoading = false;

  @override
  void initState() {
    super.initState();
    _goingCount = widget.event.goingCount;
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  _EventStatus get _eventStatus {
    final now = DateTime.now();
    if (widget.event.status == 'CANCELLED') return _EventStatus.cancelled;
    if (now.isAfter(widget.event.endDateTime)) return _EventStatus.past;
    if (now.isAfter(widget.event.startDateTime)) return _EventStatus.ongoing;
    return _EventStatus.upcoming;
  }

  bool get _isEventOver =>
      _eventStatus == _EventStatus.past ||
      _eventStatus == _EventStatus.cancelled;

  Color get _statusColor {
    switch (_eventStatus) {
      case _EventStatus.cancelled:
        return Colors.redAccent;
      case _EventStatus.past:
        return Colors.grey;
      case _EventStatus.ongoing:
        return Colors.green;
      case _EventStatus.upcoming:
        return Colors.blueAccent;
    }
  }

  String get _statusText {
    switch (_eventStatus) {
      case _EventStatus.cancelled:
        return 'Cancelled';
      case _EventStatus.past:
        return 'Past';
      case _EventStatus.ongoing:
        return 'Ongoing';
      case _EventStatus.upcoming:
        return 'Upcoming';
    }
  }

  // ── RSVP actions ────────────────────────────────────────────────────────────

  Future<void> _attend() async {
    setState(() => _isRsvpLoading = true);
    try {
      await ref.read(eventRepositoryProvider).rsvpEvent(widget.event.id);
      ref
          .read(rsvpStateProvider.notifier)
          .setAttending(widget.event.id, attending: true);
      setState(() => _goingCount++);
      // Show the Add to Google Calendar prompt
      if (mounted) {
        await CalendarDialog.show(context, widget.event);
      }
    } catch (e) {
      _showSnack('Failed to register. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isRsvpLoading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _isRsvpLoading = true);
    try {
      await ref.read(eventRepositoryProvider).cancelRsvp(widget.event.id);
      ref
          .read(rsvpStateProvider.notifier)
          .setAttending(widget.event.id, attending: false);
      setState(() => _goingCount = (_goingCount - 1).clamp(0, 999999));
      _showSnack('Attendance cancelled.');
    } catch (e) {
      _showSnack('Failed to cancel. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isRsvpLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF1E3A1E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isOrganizer = user != null &&
        widget.event.organizerId != null &&
        user.id == widget.event.organizerId;

    final rsvpMap = ref.watch(rsvpStateProvider);
    final isAttending = rsvpMap[widget.event.id] ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Colors.black,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.event.imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                              stops: [0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _imagePlaceholder(),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event.title,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _statusColor.withAlpha(128)),
                        ),
                        child: Text(
                          _statusText.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Date
                  _InfoRow(
                    icon: Icons.calendar_today,
                    iconColor: Colors.white,
                    title: _formatDate(widget.event.startDateTime),
                    subtitle:
                        '${_formatTime(widget.event.startDateTime)} — ${_formatTime(widget.event.endDateTime)}',
                  ),

                  const SizedBox(height: 14),

                  // Location
                  GestureDetector(
                    onTap: () async {
                      final url = widget.event.locationUrl;
                      if (url != null &&
                          await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: _InfoRow(
                      icon: Icons.location_on,
                      iconColor: Colors.white,
                      title: widget.event.location,
                      subtitle: widget.event.locationUrl != null
                          ? 'Tap to view on Map'
                          : null,
                      subtitleColor: AppColors.primary,
                    ),
                  ),

                  if (widget.event.maxAttendees != null) ...[
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.people_outline,
                      iconColor: Colors.white,
                      title: 'Capacity',
                      subtitle:
                          '${widget.event.maxAttendees} max attendees',
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Going count chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3A1B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people,
                                size: 14, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 6),
                            Text(
                              '$_goingCount going',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFF222222)),
                  const SizedBox(height: 16),

                  // Organizer
                  Row(
                    children: [
                      AvatarInitials(
                        initials: widget.event.organizer.isNotEmpty
                            ? widget.event.organizer[0].toUpperCase()
                            : 'U',
                        radius: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizer',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.event.organizer,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF222222)),
                  const SizedBox(height: 20),

                  // About
                  Text(
                    'About this event',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildCTA(isOrganizer: isOrganizer, isAttending: isAttending),
        ),
      ),
    );
  }

  Widget _buildCTA({required bool isOrganizer, required bool isAttending}) {
    // Past / cancelled
    if (_isEventOver) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            widget.event.status == 'CANCELLED'
                ? 'Event Cancelled'
                : 'Event Has Ended',
            style: GoogleFonts.inter(
                color: const Color(0xFF666666), fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Organizer → see attendees
    if (isOrganizer) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => AttendeesBottomSheet.show(
            context,
            widget.event.id,
            _goingCount,
          ),
          icon: const Icon(Icons.people_rounded, size: 20),
          label: Text(
            'See Attendees ($_goingCount)',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    // Cancel attendance
    if (isAttending) {
      return SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: _isRsvpLoading ? null : _cancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isRsvpLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.redAccent),
                )
              : Text(
                  'Cancel Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
        ),
      );
    }

    // Attend
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isRsvpLoading ? null : _attend,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isRsvpLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Attend',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Icon(Icons.event, size: 80, color: Color(0xFF333333)),
        ),
      );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

enum _EventStatus { upcoming, ongoing, past, cancelled }

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subtitleColor ?? const Color(0xFF888888),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
