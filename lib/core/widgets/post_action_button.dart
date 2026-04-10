import 'package:flutter/material.dart';

class PostActionButton extends StatelessWidget {
  final IconData icon;
  final String count;
  final VoidCallback onTap;
  final Color? iconColor;

  const PostActionButton({
    Key? key,
    required this.icon,
    required this.count,
    required this.onTap,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              count,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
