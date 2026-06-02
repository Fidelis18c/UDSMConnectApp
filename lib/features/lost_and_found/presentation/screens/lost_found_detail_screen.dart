import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/lost_found.dart';
import '../../data/repositories/lost_found_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/lost_found_provider.dart';

class LostFoundDetailScreen extends ConsumerStatefulWidget {
  final LostFoundItem item;

  const LostFoundDetailScreen({super.key, required this.item});

  @override
  ConsumerState<LostFoundDetailScreen> createState() =>
      _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends ConsumerState<LostFoundDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  Timer? _carouselTimer;
  late Future<LostFoundItem> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref
        .read(lostFoundRepositoryProvider)
        .getItemDetail(widget.item.id);
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      final images = widget.item.media;
      if (images.isEmpty || images.length <= 1) return;
      if (_pageController.hasClients) {
        int nextIndex = _currentImageIndex + 1;
        if (nextIndex >= images.length) {
          nextIndex = 0;
        }
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _isLost => widget.item.type == 'LOST';
  bool get _isResolved => widget.item.status == 'RESOLVED';

  Color get _typeColor =>
      _isResolved ? const Color(0xFFD32F2F) : (_isLost ? AppColors.primary : const Color(0xFF2E7D32));
  String get _typeText => _isResolved ? 'RESOLVED' : (_isLost ? 'LOST' : 'FOUND');

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isOwner = user != null && widget.item.reporter?.id == user.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<LostFoundItem>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final item =
                snapshot.connectionState == ConnectionState.done && snapshot.hasData
                    ? snapshot.data!
                    : widget.item;
            final images = item.media.isNotEmpty
                ? item.media
                : (item.coverImage != null ? [item.coverImage!] : <LostFoundMedia>[]);
            final loading = snapshot.connectionState != ConnectionState.done;

            return CustomScrollView(
              slivers: [
                // ── Image Carousel ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: images.isEmpty
                            ? Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 64,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImageIndex = i),
                                itemBuilder: (_, i) => Image.network(
                                  images[i].url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1A1A1A),
                                    child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: Color(0xFF444444)),
                                  ),
                                ),
                              ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),

                      // Owner Options
                      if (isOwner)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 12,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              popupMenuTheme: const PopupMenuThemeData(
                                color: Color(0xFF1E1E1E),
                                textStyle: TextStyle(color: Colors.white),
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(153),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.more_vert,
                                    color: Colors.white, size: 20),
                              ),
                              onSelected: (value) async {
                                if (value == 'resolve') {
                                  final success = await ref
                                      .read(lostFoundItemsProvider.notifier)
                                      .resolveItem(widget.item.id);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item marked as resolved')),
                                    );
                                    Navigator.pop(context);
                                  }
                                } else if (value == 'delete') {
                                  final conf = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      title: const Text('Delete Report?', style: TextStyle(color: Colors.white)),
                                      content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('CANCEL', style: TextStyle(color: AppColors.textHint)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (conf == true && mounted) {
                                    final success = await ref
                                        .read(lostFoundItemsProvider.notifier)
                                        .deleteItem(widget.item.id);
                                    if (success && mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                if (!_isResolved)
                                  const PopupMenuItem(
                                    value: 'resolve',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                        SizedBox(width: 12),
                                        Text('Mark as Resolved'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      SizedBox(width: 12),
                                      Text('Delete Report', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Image counter
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(153),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info card ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _typeColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _typeColor),
                                ),
                                child: Text(
                                  _typeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _typeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(color: Color(0xFF2E2E2E), height: 24),

                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else ...[
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: item.location ?? '—',
                          ),
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Posted by',
                            value: item.reporter?.fullName ?? 'Anonymous',
                          ),
                          if (item.contactInfo != null &&
                              item.contactInfo!.isNotEmpty) ...[
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Contact',
                              value: item.contactInfo!,
                            ),
                          ],
                          _InfoRow(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: item.category?.name ?? '—',
                          ),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date',
                            value: _formatDate(item.dateLostFound),
                          ),
                          _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Description',
                            value: item.description.isNotEmpty
                                ? item.description
                                : '—',
                            multiline: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Contact actions ──────────────────────────────────────
                if (widget.item.contactInfo != null &&
                    widget.item.contactInfo!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Contact',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ContactButton(
                            icon: Icons.phone_rounded,
                            label: 'Call',
                            onTap: () =>
                                _launch('tel:${widget.item.contactInfo}'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: multiline ? null : 2,
                  overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
