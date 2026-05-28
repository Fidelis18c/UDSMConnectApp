import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:udsm_connect/features/announcements/presentation/providers/stories_provider.dart';
import 'package:udsm_connect/features/stories/presentation/widgets/story_progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryViewerArgs {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  StoryViewerArgs({required this.groups, required this.initialGroupIndex});
}

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryViewerArgs args;

  const StoryViewerScreen({Key? key, required this.args}) : super(key: key);

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.args.initialGroupIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStory();
  }

  void _loadStory() {
    _animationController.reset();

    final group = widget.args.groups[_currentGroupIndex];
    if (group.stories.isNotEmpty) {
      final story = group.stories[_currentStoryIndex];
      if (!story.hasViewed) {
        ref.read(storiesProvider.notifier).markViewed(story.id);
      }
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStory() {
    final group = widget.args.groups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      if (_currentGroupIndex < widget.args.groups.length - 1) {
        setState(() {
          _currentGroupIndex++;
          _currentStoryIndex = 0;
        });
        _loadStory();
      } else {
        context.pop();
      }
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory();
    } else {
      if (_currentGroupIndex > 0) {
        setState(() {
          _currentGroupIndex--;
          _currentStoryIndex = widget.args.groups[_currentGroupIndex].stories.length - 1;
        });
        _loadStory();
      } else {
        _loadStory(); // restart current
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.stop();
  }

  void _onTapUp(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width / 3) {
      _previousStory();
    } else {
      _nextStory();
    }
  }



  void _onLongPressEnd(LongPressEndDetails details) {
    _animationController.forward();
  }

  String _timeAgo(DateTime dateTime) {
    final dur = DateTime.now().difference(dateTime);
    if (dur.inMinutes < 60) return '${dur.inMinutes}m';
    if (dur.inHours < 24) return '${dur.inHours}h';
    return '${dur.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.args.groups[_currentGroupIndex];
    final story = group.stories[_currentStoryIndex];

    Color bgColor = Colors.black;
    if (story.backgroundColor != null && story.backgroundColor!.startsWith('#')) {
      final hex = story.backgroundColor!.replaceFirst('#', 'FF');
      bgColor = Color(int.tryParse(hex, radix: 16) ?? 0xFF000000);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,

        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: () => _animationController.forward(),
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 10) {
            context.pop();
          }
        },
        child: Stack(
          children: [
            // Background Image/Color
            Container(
              width: double.infinity,
              height: double.infinity,
              color: bgColor,
              child: story.media != null
                  ? Image.network(
                      story.media!.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.broken_image, color: Colors.white.withOpacity(0.5), size: 50),
                        );
                      },
                    )
                  : null,
            ),
            
            // Top Gradient for Text Readability
            Positioned(
              top: 0, left: 0, right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom Gradient for Caption Readability
            if (story.caption != null || story.linkUrl != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

            // Top Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  children: [
                    StoryProgressBar(
                      animationController: _animationController,
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
                              : NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.label)}&background=random') as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          group.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(story.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
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

            // Bottom Content
            if (story.caption != null || story.linkUrl != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (story.caption != null)
                          Text(
                            story.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                            ),
                          ),
                        if (story.caption != null && story.linkUrl != null)
                          const SizedBox(height: 12),
                        if (story.linkUrl != null)
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                final uri = Uri.parse(story.linkUrl!);
                                if (await canLaunchUrl(uri)) {
                                  _animationController.stop();
                                  await launchUrl(uri);
                                  // Optionally resume when back
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    story.linkText?.isNotEmpty == true ? story.linkText! : 'Listen / Explore',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new, size: 16),
                                ],
                              ),
                            ),
                          ),
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
