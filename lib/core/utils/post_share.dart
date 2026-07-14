import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Canonical public share URLs (must match the Next.js page at `/posts/[id]`).
class PostShare {
  /// Override for local testing: `--dart-define=SHARE_BASE_URL=http://192.168.x.x:3000`
  static const String baseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: 'https://www.udsminfo.com',
  );

  static String postUrl(String postId) =>
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/posts/$postId';

  /// Title/body + public link so recipients can open the post.
  static String shareText({
    required String postId,
    String title = '',
    String text = '',
  }) {
    final url = postUrl(postId);
    final parts = <String>[
      if (title.trim().isNotEmpty) title.trim(),
      if (text.trim().isNotEmpty) text.trim(),
      url,
    ];
    return parts.join('\n\n');
  }

  static Future<void> sharePost({
    required String postId,
    String title = '',
    String text = '',
    Rect? sharePositionOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        text: shareText(postId: postId, title: title, text: text),
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
