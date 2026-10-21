import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// Shared chrome (header, score pills, hint bar, status cards) for the game
/// screens so every game matches the Metromate design system.

/// Extra gradients used by the game screens (on top of the AppTheme set).
class GamesPalette {
  GamesPalette._();

  static const LinearGradient amber = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class GameStat {
  final String label;
  final String value;
  final IconData icon;
  const GameStat(this.label, this.value, this.icon);
}

/// Gradient header with back button, play/restart actions and score pills.
class GameHeader extends StatelessWidget {
  final String title;
  final LinearGradient gradient;
  final List<GameStat> stats;
  final List<Widget>? actions;

  const GameHeader({
    super.key,
    required this.title,
    required this.gradient,
    required this.stats,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      title: title,
      gradient: gradient,
      actions: actions == null
          ? null
          : [
              for (var i = 0; i < actions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions![i],
              ],
            ],
      bottom: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _StatPill(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final GameStat stat;
  const _StatPill({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(stat.icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tinted instruction bar shown above the action buttons.
class GameHintBar extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const GameHintBar({super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: p.tint(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card used for "Game Over", "Paused", "You Win" states.
class GameStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  final Color color;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final LinearGradient actionGradient;

  const GameStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.lines = const [],
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionGradient = AppTheme.sunsetGradient,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppTheme.glow(color, alpha: 0.25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBubble(icon: icon, color: color, filled: true, size: 60, radius: 20),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.4),
          ),
          for (final line in lines) ...[
            const SizedBox(height: 4),
            Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textSecondary),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            GradientButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              gradient: actionGradient,
            ),
          ],
        ],
      ),
    );
  }
}

/// Dims the board and centres a [GameStatusCard] on top of it.
class GameOverlay extends StatelessWidget {
  final Widget child;
  const GameOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: context.palette.background.withValues(alpha: 0.55),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}
