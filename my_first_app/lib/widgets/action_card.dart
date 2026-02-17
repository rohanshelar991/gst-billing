import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ActionCard extends StatefulWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor = primaryBlue,
    this.centerContent = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final bool centerContent;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = isDark ? darkCard : whiteCard;
    final Color tintedSurface = Color.alphaBlend(
      widget.accentColor.withValues(alpha: isDark ? 0.34 : 0.30),
      surface,
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.97 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: tintedSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: isDark ? 0.54 : 0.48),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: widget.centerContent
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: widget.centerContent
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(
                        alpha: isDark ? 0.46 : 0.40,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.accentColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: widget.centerContent
                        ? TextAlign.center
                        : TextAlign.start,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    textAlign: widget.centerContent
                        ? TextAlign.center
                        : TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
