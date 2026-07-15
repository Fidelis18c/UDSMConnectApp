import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:udsm_connect/core/models/story.dart';
import 'package:udsm_connect/core/utils/story_grouping.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/stories_provider.dart';
import 'package:udsm_connect/features/comments/presentation/providers/comments_provider.dart';
import 'package:udsm_connect/features/comments/presentation/widgets/comment_section.dart';
import 'package:udsm_connect/features/stories/presentation/widgets/story_progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Instagram-style full-screen story viewer:
/// - Segmented progress bar
/// - Hold to pause
/// - Tap left/right thirds for prev/next
/// - Double-tap to like (heart burst)
/// - Bottom reply + like + comments
/// - Swipe down to dismiss
class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryViewerArgs args;

  const StoryViewerScreen({Key? key, required this.args}) : super(key: key);

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with TickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 7);

  late AnimationController _progressController;
  late AnimationController _heartController;
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;

  bool _isPaused = false;
  bool _isHolding = false;
  bool _sheetOpen = false;
  bool _showHeart = false;
  Offset? _heartPosition;
  Timer? _tapNavTimer;
  Offset? _lastTapUpPos;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _sendingReply = false;

  // Local interaction state keyed by story id (survives group switches)
  final Map<String, _StoryInteractState> _local = {};

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.args.initialGroupIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused && !_sheetOpen) {
        _nextStory();
      }
    });

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
      }
    });

    _replyFocus.addListener(() {
      if (_replyFocus.hasFocus) {
        _pause();
      } else if (!_sheetOpen) {
        _resume();
      }
    });

    _loadStory();
  }

  Story get _currentStory =>
      widget.args.groups[_currentGroupIndex].stories[_currentStoryIndex];

  _StoryInteractState _stateFor(Story story) {
    return _local.putIfAbsent(
      story.id,
      () => _StoryInteractState(
        isLiked: story.isLiked,
        likeCount: story.likeCount,
        commentCount: story.commentCount,
      ),
    );
  }

  void _loadStory() {
    _progressController
      ..duration = _storyDuration
      ..reset();

    final story = _currentStory;
    // Seed local state from provider when available
    final providerStories = ref.read(storiesProvider).value;
    if (providerStories != null) {
      for (final s in providerStories) {
        if (s.id == story.id) {
          _local[story.id] = _StoryInteractState(
            isLiked: s.isLiked,
            likeCount: s.likeCount,
            commentCount: s.commentCount,
          );
          break;
        }
      }
    }
    _stateFor(story);

    if (!story.hasViewed) {
      ref.read(storiesProvider.notifier).markViewed(story.id);
    }

    _precacheNearby();

    if (!_isPaused && !_sheetOpen && !_replyFocus.hasFocus) {
      _progressController.forward();
    }
  }

  /// Prefetch next/prev media so story advances feel Instagram-smooth.
  void _precacheNearby() {
    final groups = widget.args.groups;
    final urls = <String>[];

    void addStory(Story s) {
      final url = s.media?.url;
      if (url != null && url.isNotEmpty) urls.add(url);
    }

    final group = groups[_currentGroupIndex];
    if (_currentStoryIndex + 1 < group.stories.length) {
      addStory(group.stories[_currentStoryIndex + 1]);
    } else if (_currentGroupIndex + 1 < groups.length) {
      final next = groups[_currentGroupIndex + 1];
      if (next.stories.isNotEmpty) addStory(next.stories.first);
    }
    if (_currentStoryIndex > 0) {
      addStory(group.stories[_currentStoryIndex - 1]);
    }

    for (final url in urls) {
      precacheImage(NetworkImage(url), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _tapNavTimer?.cancel();
    _progressController.dispose();
    _heartController.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
  }

  void _resume() {
    if (!_isPaused || _sheetOpen || _replyFocus.hasFocus) return;
    _isPaused = false;
    if (_progressController.status != AnimationStatus.completed) {
      _progressController.forward();
    }
  }

  void _nextStory() {
    final group = widget.args.groups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _loadStory();
    } else if (_currentGroupIndex < widget.args.groups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _loadStory();
    } else {
      if (mounted) context.pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _loadStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex =
            widget.args.groups[_currentGroupIndex].stories.length - 1;
      });
      _loadStory();
    } else {
      _progressController
        ..reset()
        ..forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isHolding) {
      _isHolding = false;
      _resume();
      return;
    }
    if (_replyFocus.hasFocus) {
      _replyFocus.unfocus();
      return;
    }

    // Delay navigation so double-tap can cancel (Instagram: double-tap likes)
    _lastTapUpPos = details.globalPosition;
    _tapNavTimer?.cancel();
    _tapNavTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || _isHolding || _sheetOpen) return;
      final pos = _lastTapUpPos;
      if (pos == null) return;
      final width = MediaQuery.of(context).size.width;
      if (pos.dx < width * 0.3) {
        _previousStory();
      } else {
        _nextStory();
      }
    });
  }

  void _onLongPressStart(LongPressStartDetails _) {
    _tapNavTimer?.cancel();
    _isHolding = true;
    _pause();
    HapticFeedback.selectionClick();
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _isHolding = false;
    _resume();
  }

  Future<void> _toggleLike({bool forceLike = false, Offset? at}) async {
    final story = _currentStory;
    final local = _stateFor(story);

    if (forceLike && local.isLiked) {
      // Double-tap only likes, never unlikes (Instagram behaviour)
      _burstHeart(at);
      return;
    }

    final nextLiked = forceLike ? true : !local.isLiked;
    final delta = nextLiked == local.isLiked ? 0 : (nextLiked ? 1 : -1);

    setState(() {
      local.isLiked = nextLiked;
      local.likeCount = (local.likeCount + delta).clamp(0, 1 << 30);
    });

    if (nextLiked) {
      _burstHeart(at);
      HapticFeedback.lightImpact();
    }

    try {
      await ref.read(storiesProvider.notifier).toggleLike(story.id);
      // Re-sync from provider
      final list = ref.read(storiesProvider).value;
      if (list != null) {
        for (final s in list) {
          if (s.id == story.id) {
            setState(() {
              local.isLiked = s.isLiked;
              local.likeCount = s.likeCount;
            });
            break;
          }
        }
      }
    } catch (_) {
      // Provider already rolls back; re-seed local
      setState(() {
        local.isLiked = !nextLiked;
        local.likeCount = (local.likeCount - delta).clamp(0, 1 << 30);
      });
    }
  }

  void _burstHeart(Offset? at) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _showHeart = true;
      _heartPosition = at ?? Offset(size.width / 2, size.height / 2 - 40);
    });
    _heartController
      ..reset()
      ..forward();
  }

  Future<void> _openComments() async {
    final story = _currentStory;
    final local = _stateFor(story);
    _pause();
    _sheetOpen = true;
    _replyFocus.unfocus();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${local.commentCount}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    Expanded(
                      child: Theme(
                        data: ThemeData.dark().copyWith(
                          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: CommentSection(
                            targetId: story.id,
                            targetType: 'STORY',
                            showInput: false,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                        child: NewCommentBox(
                          params: CommentsParams(
                            targetId: story.id,
                            targetType: 'STORY',
                          ),
                          hintOverride: 'Leave a comment…',
                          onSuccess: () {
                            setState(() => local.commentCount++);
                            ref
                                .read(storiesProvider.notifier)
                                .updateCommentCount(story.id, 1);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;
    _sheetOpen = false;
    _resume();
  }

  Future<void> _sendQuickReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;

    final story = _currentStory;
    final local = _stateFor(story);
    setState(() => _sendingReply = true);

    final ok = await ref.read(commentsMutationsProvider).post(
          params: CommentsParams(targetId: story.id, targetType: 'STORY'),
          content: text,
        );

    if (!mounted) return;
    setState(() => _sendingReply = false);

    if (ok) {
      _replyController.clear();
      _replyFocus.unfocus();
      setState(() => local.commentCount++);
      ref.read(storiesProvider.notifier).updateCommentCount(story.id, 1);
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment sent'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _resume();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send comment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _timeAgo(DateTime dateTime) {
    final dur = DateTime.now().difference(dateTime);
    if (dur.inSeconds < 60) return 'now';
    if (dur.inMinutes < 60) return '${dur.inMinutes}m';
    if (dur.inHours < 24) return '${dur.inHours}h';
    return '${dur.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.args.groups[_currentGroupIndex];
    final story = _currentStory;
    final local = _stateFor(story);

    Color bgColor = Colors.black;
    if (story.backgroundColor != null &&
        story.backgroundColor!.startsWith('#')) {
      final hex = story.backgroundColor!.replaceFirst('#', 'FF');
      bgColor = Color(int.tryParse(hex, radix: 16) ?? 0xFF000000);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          // Soft pause on press-down (before long-press threshold)
          if (!_replyFocus.hasFocus) {
            _progressController.stop();
          }
        },
        onTapUp: _onTapUp,
        onTapCancel: () {
          if (!_isHolding && !_sheetOpen && !_replyFocus.hasFocus) {
            _progressController.forward();
          }
        },
        onDoubleTapDown: (d) {
          _tapNavTimer?.cancel();
          _toggleLike(forceLike: true, at: d.globalPosition);
          // Resume progress after like (tapDown soft-paused the bar)
          if (!_isHolding && !_sheetOpen && !_replyFocus.hasFocus) {
            _isPaused = false;
            _progressController.forward();
          }
        },
        onDoubleTap: () {
          // Cancels single-tap navigation; like handled in onDoubleTapDown
        },
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: () {
          _isHolding = false;
          _resume();
        },
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! > 12) {
            context.pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media / color background
            Container(
              color: bgColor,
              child: story.media != null
                  ? Image.network(
                      story.media!.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white.withOpacity(0.4),
                          size: 48,
                        ),
                      ),
                    )
                  : null,
            ),

            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Header: progress + author
            SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                    StoryProgressBar(
                      animationController: _progressController,
                      currentIndex: _currentStoryIndex,
                      totalCount: group.stories.length,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: group.imageUrl != null
                              ? NetworkImage(group.imageUrl!)
                              : NetworkImage(
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.label)}&background=random',
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${story.author.fullName} · ${_timeAgo(story.createdAt)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (story.viewCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${story.viewCount}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Caption + link
            if (story.caption != null || story.linkUrl != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 88 + MediaQuery.of(context).padding.bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (story.caption != null)
                      Text(
                        story.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.35,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    if (story.linkUrl != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.tryParse(story.linkUrl!);
                          if (uri == null) return;
                          _pause();
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                          if (mounted) _resume();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                story.linkText?.isNotEmpty == true
                                    ? story.linkText!
                                    : 'Open link',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.open_in_new,
                                  size: 15, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Bottom interaction bar (Instagram-style)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.45),
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  focusNode: _replyFocus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  cursorColor: Colors.white,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendQuickReply(),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Send message…',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (_sendingReply)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _sendQuickReply,
                                  child: Icon(
                                    Icons.send_rounded,
                                    size: 20,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Like
                      _CircleAction(
                        onTap: () => _toggleLike(),
                        child: Icon(
                          local.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: local.isLiked
                              ? const Color(0xFFFF3040)
                              : Colors.white,
                          size: 26,
                        ),
                      ),
                      if (local.likeCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 2, right: 4),
                          child: Text(
                            '${local.likeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      // Comments
                      _CircleAction(
                        onTap: _openComments,
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      if (local.commentCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            '${local.commentCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Double-tap heart overlay
            if (_showHeart && _heartPosition != null)
              Positioned(
                left: _heartPosition!.dx - 48,
                top: _heartPosition!.dy - 48,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _heartController,
                    builder: (context, child) {
                      final t = _heartController.value;
                      // Scale up then fade out
                      final scale = t < 0.25
                          ? Curves.easeOutBack.transform(t / 0.25)
                          : 1.0 + (t - 0.25) * 0.15;
                      final opacity = t < 0.55
                          ? 1.0
                          : (1.0 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale * 1.15,
                          child: child,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF3040),
                      size: 96,
                      shadows: [
                        Shadow(blurRadius: 12, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryInteractState {
  bool isLiked;
  int likeCount;
  int commentCount;

  _StoryInteractState({
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
  });
}

class _CircleAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CircleAction({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
