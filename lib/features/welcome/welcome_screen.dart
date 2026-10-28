import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_widgets.dart';

/// A1 Welcome, ported from the Figma Make `Welcome` screen.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: YaadlyColors.butter,
      body: Stack(
        children: [
          // Decorative sun in the top-right corner.
          const Positioned(
            right: -64,
            top: -64,
            child: SizedBox(
              width: 224,
              height: 224,
              child: DecoratedBox(decoration: BoxDecoration(color: YaadlyColors.sun, shape: BoxShape.circle)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.welcomeKicker.toUpperCase(), style: YaadlyText.labelCaps()),
                  const Gap(12),
                  Semantics(
                    header: true,
                    label: 'Yaadly',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yaad', style: YaadlyText.display(size: 76).copyWith(height: 0.9)),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text('ly', style: YaadlyText.display(size: 76).copyWith(height: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 256),
                    child: Text.rich(
                      TextSpan(
                        style: YaadlyText.body(size: 17),
                        children: [
                          TextSpan(text: s.welcomeTagline),
                          TextSpan(text: s.welcomeTaglineStrong, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(child: _SampleCards()),
                  YButton(label: s.welcomeStart, large: true, expand: true, onPressed: () => context.go(Routes.link)),
                  const Gap(16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(Routes.link),
                      child: Text(
                        s.welcomeHaveAccount,
                        style: YaadlyText.body(size: 14, weight: FontWeight.w600, color: YaadlyColors.clay).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: YaadlyColors.clay,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three tilted sample cards: voice note → parsed event → saved confirmation.
class _SampleCards extends ConsumerWidget {
  const _SampleCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 8,
                width: c.maxWidth * 0.78,
                child: Transform.rotate(angle: -3 * math.pi / 180, child: const VoicePill()),
              ),
              Positioned(
                right: 0,
                top: 72,
                width: c.maxWidth * 0.84,
                child: Transform.rotate(
                  angle: 2 * math.pi / 180,
                  child: HardBox(
                    color: YaadlyColors.sand,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(4),
                      bottomLeft: Radius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.welcomeSampleQuote,
                          style: YaadlyText.body(size: 12, color: YaadlyColors.clay).copyWith(fontStyle: FontStyle.italic),
                        ),
                        const Gap(12),
                        Text(s.welcomeSampleWhen.toUpperCase(), style: YaadlyText.labelCaps()),
                        const Gap(4),
                        Text(s.welcomeSampleTitle, style: YaadlyText.display(size: 24).copyWith(height: 1)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 0,
                child: Transform.rotate(
                  angle: -2 * math.pi / 180,
                  child: HardBox.small(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('✅  ${s.welcomeSampleSaved}', style: YaadlyText.body(size: 14, weight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
