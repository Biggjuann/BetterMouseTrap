import 'package:flutter/material.dart';
import '../theme.dart';

// ── Studio shared widgets ───────────────────────────────────────────
//
// Tiny design-system primitives used across every Studio screen. Keep
// this file tight and additive — if a screen needs a one-off, build it
// inline; if it shows up twice, promote it here.
//

// ── Eyebrow — small caps, mono, 2pt tracking ────────────────────────
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const Eyebrow(this.text, {super.key, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    final w = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: fontMono,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.mist,
        letterSpacing: 2,
      ),
    );
    return padding != null ? Padding(padding: padding!, child: w) : w;
  }
}

// ── StudioChip — pill with 3 tones ──────────────────────────────────
enum ChipTone { ink, accent, ghost, warm, sun }

class StudioChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final Widget? leading;
  final double size;

  const StudioChip({
    super.key,
    required this.label,
    this.tone = ChipTone.ghost,
    this.leading,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, border, fg;
    switch (tone) {
      case ChipTone.ink:
        bg = AppColors.ink; border = AppColors.ink; fg = AppColors.canvas;
        break;
      case ChipTone.accent:
        bg = AppColors.accentSoft; border = Colors.transparent; fg = AppColors.accentInk;
        break;
      case ChipTone.warm:
        bg = AppColors.warmSoft; border = Colors.transparent; fg = AppColors.warm;
        break;
      case ChipTone.sun:
        bg = AppColors.sunSoft; border = Colors.transparent; fg = AppColors.ink;
        break;
      case ChipTone.ghost:
      bg = AppColors.canvas; border = AppColors.hairline; fg = AppColors.graphite;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.9, vertical: size * 0.35),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: fontSans,
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier helpers ────────────────────────────────────────────────────
enum Tier { top, moonshot, upgrade, adjacent, recurring }

Tier tierOf(String s) {
  switch (s) {
    case 'moonshot':  return Tier.moonshot;
    case 'upgrade':   return Tier.upgrade;
    case 'adjacent':  return Tier.adjacent;
    case 'recurring': return Tier.recurring;
    default:          return Tier.top;
  }
}

extension TierMeta on Tier {
  Color get color {
    switch (this) {
      case Tier.top:       return AppColors.top;
      case Tier.moonshot:  return AppColors.moonshot;
      case Tier.upgrade:   return AppColors.upgrade;
      case Tier.adjacent:  return AppColors.adjacent;
      case Tier.recurring: return AppColors.recurring;
    }
  }
  String get label {
    switch (this) {
      case Tier.top:       return 'Top pick';
      case Tier.moonshot:  return 'Moonshot';
      case Tier.upgrade:   return 'Upgrade';
      case Tier.adjacent:  return 'Adjacent';
      case Tier.recurring: return 'Recurring';
    }
  }
}

class TierDot extends StatelessWidget {
  final Tier tier;
  final double size;
  const TierDot(this.tier, {super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tier.color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── ScoreBar — thin progress line ───────────────────────────────────
class ScoreBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const ScoreBar({super.key, required this.value, this.color, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(height),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? AppColors.top,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

// ── SectionHeader — eyebrow + display title + rule ──────────────────
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    this.eyebrow = '',
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(eyebrow)),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontFamily: fontMono,
                    fontSize: 11,
                    color: AppColors.mist,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppText.display3),
        ],
      ),
    );
  }
}

// ── StudioCard — canvas surface, hairline border ────────────────────
class StudioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final BorderRadius? radius;
  final VoidCallback? onTap;
  final Border? border;

  const StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.background,
    this.radius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(AppRadius.lg);
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.canvas,
        borderRadius: br,
        border: border ?? Border.all(color: AppColors.hairline),
      ),
      child: child,
    );
    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: inner,
      ),
    );
  }
}

// ── Primary button variants ─────────────────────────────────────────

enum BtnKind { primary, accent, ghost, sun }

class StudioButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BtnKind kind;
  final bool full;
  final bool large;
  final Widget? leading;

  const StudioButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = BtnKind.primary,
    this.full = true,
    this.large = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    Border? border;
    switch (kind) {
      case BtnKind.primary:
        bg = AppColors.ink; fg = AppColors.canvas;
        break;
      case BtnKind.accent:
        bg = AppColors.accent; fg = Colors.white;
        break;
      case BtnKind.sun:
        bg = AppColors.sun; fg = AppColors.ink;
        break;
      case BtnKind.ghost:
        bg = AppColors.canvas; fg = AppColors.ink;
        border = Border.all(color: AppColors.border);
        break;
    }

    final btn = Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 22,
            vertical: large ? 17 : 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontSans,
                  fontSize: large ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (full) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}

// ── IconBtn — small circular icon button for nav headers ────────────
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? background;

  const IconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 38,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size / 2),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.48, color: color ?? AppColors.ink),
        ),
      ),
    );
  }
}

// ── Placeholder — asset stand-in, used for imagery we haven't sourced
class StudioPlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final Color? background;

  const StudioPlaceholder({
    super.key,
    required this.label,
    this.height = 160,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: background ?? AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Eyebrow(label, color: AppColors.accentInk),
      ),
    );
  }
}
