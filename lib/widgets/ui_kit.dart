import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_theme.dart';

/// Shared design-system building blocks used across Metromate screens.
///
/// Usage: `context.palette.card`, `GradientHeader(...)`, `AppCard(...)`,
/// `SectionHeader(...)`, `IconBubble(...)`, `GradientButton(...)`.

// ── Theme-aware palette ─────────────────────────────────────────────────────

class AppPalette {
  final bool isDark;
  const AppPalette(this.isDark);

  Color get background => isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.surfaceColor;
  Color get card => isDark ? AppTheme.darkCard : AppTheme.cardColor;
  Color get cardAlt => isDark ? const Color(0xFF20254F) : AppTheme.surfaceTint;
  Color get border => isDark ? AppTheme.darkBorder : AppTheme.dividerColor;
  Color get textPrimary => isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get textSecondary => isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get textTertiary => isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary;
  Color get primary => isDark ? const Color(0xFF818CF8) : AppTheme.primaryColor;
  Color get accent => AppTheme.accentColor;

  /// Soft tinted background for an accent colour (chips, icon bubbles).
  Color tint(Color c) => c.withValues(alpha: isDark ? 0.2 : 0.1);

  List<BoxShadow> get shadow => isDark ? const [] : AppTheme.cardShadow;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => AppPalette(Theme.of(this).brightness == Brightness.dark);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ── Gradient page header ────────────────────────────────────────────────────

/// Immersive gradient header used at the top of screens instead of a plain AppBar.
/// Place it as the first child of a scroll view (or in a [Column]).
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Gradient gradient;
  final List<Widget>? actions;
  final Widget? bottom;
  final String? illustration;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradient = AppTheme.heroGradient,
    this.actions,
    this.bottom,
    this.illustration,
    this.showBack = true,
    this.onBack,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            const Positioned(top: -60, right: -40, child: _GlowCircle(size: 180, alpha: 0.10)),
            const Positioned(bottom: -50, left: -30, child: _GlowCircle(size: 140, alpha: 0.07)),
            if (illustration != null)
              // Sits beside the title, below the action buttons row
              Positioned(
                right: -8,
                top: topPad + 52,
                child: Opacity(
                  opacity: 0.95,
                  child: SvgPicture.asset(illustration!, width: 96, height: 96),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, bottom == null ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (leading != null)
                        leading!
                      else if (showBack && (canPop || onBack != null))
                        HeaderIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onTap: onBack ?? () => context.pop(),
                        ),
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: illustration != null ? 80 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: 18),
                    bottom!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double alpha;
  const _GlowCircle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Frosted round icon button for use on gradient headers.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool showDot;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (showDot)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12.5, color: p.textTertiary)),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.accentColor,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cards ───────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.gradient,
    this.color,
    this.radius = 20,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final br = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.card) : null,
        gradient: gradient,
        borderRadius: br,
        border: showBorder && gradient == null ? Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)) : null,
        boxShadow: gradient != null
            ? AppTheme.glow((gradient as LinearGradient).colors.last, alpha: 0.28)
            : p.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;
  final double radius;

  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.filled = false,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? null : p.tint(color),
        gradient: filled
            ? LinearGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: filled ? AppTheme.glow(color, alpha: 0.3) : null,
      ),
      child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.5),
    );
  }
}

class TagPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const TagPill({super.key, required this.label, required this.color, this.icon, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : context.palette.tint(color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = AppTheme.sunsetGradient,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled ? null : AppTheme.glow((gradient as LinearGradient).colors.last, alpha: 0.35),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
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

/// Small metric tile — value over label — for stats rows.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatTile({super.key, required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color, size: 34, radius: 10),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.3),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty / error state with an illustration.
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String illustration;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration = 'assets/images/empty_route.svg',
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(illustration, width: 170),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: p.textSecondary)),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}
