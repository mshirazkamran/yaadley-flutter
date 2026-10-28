import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/yaadly_colors.dart';
import '../theme/yaadly_theme.dart';
import 'hard_box.dart';
import 'yaadly_icon.dart';

enum YButtonVariant { sun, ink, paper }

/// `Btn` from the design: hard outline, asymmetric "speech bubble" corner.
class YButton extends StatelessWidget {
  const YButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = YButtonVariant.sun,
    this.expand = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final YButtonVariant variant;
  final bool expand;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      YButtonVariant.sun => (YaadlyColors.sun, YaadlyColors.ink),
      YButtonVariant.ink => (YaadlyColors.ink, YaadlyColors.butter),
      YButtonVariant.paper => (YaadlyColors.paper, YaadlyColors.ink),
    };
    final box = HardBox(
      color: bg,
      radius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(14),
        bottomRight: Radius.circular(14),
        bottomLeft: Radius.circular(4),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: large ? 16 : 12),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: YaadlyText.display(size: large ? 18 : 15, weight: FontWeight.w600, color: fg).copyWith(height: 1.2),
      ),
    );
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      child: expand ? SizedBox(width: double.infinity, child: box) : box,
    );
  }
}

enum YChipTone { butter, sand, sun, rust, ink }

class YChip extends StatelessWidget {
  const YChip(this.label, {super.key, this.tone = YChipTone.butter, this.leading});

  final String label;
  final YChipTone tone;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      YChipTone.butter => (YaadlyColors.butter, YaadlyColors.ink),
      YChipTone.sand => (YaadlyColors.sand, YaadlyColors.ink),
      YChipTone.sun => (YaadlyColors.sun, YaadlyColors.ink),
      YChipTone.rust => (YaadlyColors.rust, YaadlyColors.paper),
      YChipTone.ink => (YaadlyColors.ink, YaadlyColors.butter),
    };
    return HardBox.small(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const Gap(4)],
          Text(label, style: YaadlyText.body(size: 12, weight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Voice-note pill: dark play button, ink/tan waveform, duration on the right.
class VoicePill extends StatelessWidget {
  const VoicePill({super.key, this.duration = '0:07'});

  final String duration;

  static const _wave = [6, 12, 8, 16, 10, 20, 14, 8, 18, 12, 6, 14, 20, 10, 16, 8, 12, 6, 10, 14];

  @override
  Widget build(BuildContext context) {
    return HardBox.small(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: YaadlyColors.ink, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const YaadlyIcon(YaadlyIcons.play, size: 16, color: YaadlyColors.butter),
          ),
          const Gap(12),
          Expanded(
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  for (var i = 0; i < _wave.length; i++)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 3,
                          height: _wave[i].toDouble(),
                          decoration: BoxDecoration(
                            color: i % 3 == 0 ? YaadlyColors.tan : YaadlyColors.ink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Text(
            duration,
            style: YaadlyText.body(size: 12, weight: FontWeight.w600, color: YaadlyColors.clay)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// Page header: optional "Wapas" back link, kicker label and a big display title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.kicker, this.onBack, this.backLabel, this.trailing});

  final String title;
  final String? kicker;
  final VoidCallback? onBack;
  final String? backLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(YaadlySpace.page, 24, YaadlySpace.page, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Pressable(
                      onTap: onBack,
                      semanticLabel: backLabel,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const YaadlyIcon(YaadlyIcons.back, size: 18, color: YaadlyColors.clay),
                          Text(backLabel ?? '', style: YaadlyText.body(size: 14, weight: FontWeight.w600, color: YaadlyColors.clay)),
                        ],
                      ),
                    ),
                  ),
                if (kicker != null) ...[Text(kicker!.toUpperCase(), style: YaadlyText.labelCaps()), const Gap(4)],
                Text(title, style: YaadlyText.display()),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Centered empty state used by screens without data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final YaadlyIcons icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page, vertical: 32),
      child: HardBox(
        color: YaadlyColors.butter,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            YaadlyIcon(icon, size: 28, color: YaadlyColors.ink),
            const Gap(16),
            Expanded(child: Text(message, style: YaadlyText.display(size: 18, weight: FontWeight.w600).copyWith(height: 1.2))),
          ],
        ),
      ),
    );
  }
}
