import 'package:flutter/material.dart';
import '../theme.dart';

// ── Pill: small rounded chip ─────────────────────────────────────────
class Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final double fontSize;
  const Pill(this.label,
      {super.key,
      this.bg = AppColors.lavLight,
      this.fg = AppColors.lavDark,
      this.fontSize = 11});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label,
          style: AppText.pill.copyWith(color: fg, fontSize: fontSize)),
    );
  }
}

// ── WCard: default white rounded card ────────────────────────────────
class WCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  const WCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: card);
  }
}

// ── PrimaryBtn: full-width lavender gradient pill button ─────────────
class PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final IconData? leading;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryBtn({
    super.key,
    required this.label,
    this.trailing,
    this.leading,
    this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          gradient: const LinearGradient(
            colors: [Color(0xFFA78BFA), AppColors.lav],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppShadows.button,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                  else ...[
                    if (leading != null) ...[
                      Icon(leading, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: AppText.btnPrimary),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailing, color: Colors.white, size: 18),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── SoftBtn: tinted pill button ──────────────────────────────────────
class SoftBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final VoidCallback? onPressed;
  const SoftBtn({
    super.key,
    required this.label,
    this.icon,
    this.bg = AppColors.lavLight,
    this.fg = AppColors.lavDark,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppText.btnSoft.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── IconBtn: small circular button ───────────────────────────────────
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const IconBtn({super.key, required this.icon, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

// ── Mascot: 6 Whiskers poses ─────────────────────────────────────────
enum MascotPose { cheese, inventor, detective, ideabox, hero, guardian }

class Mascot extends StatelessWidget {
  final MascotPose pose;
  final double size;
  const Mascot({super.key, this.pose = MascotPose.cheese, this.size = 64});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/mascot/${pose.name}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// ── SectionHeader ─────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.sectionTitle),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.caption.copyWith(
                      color: AppColors.lavDark,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
