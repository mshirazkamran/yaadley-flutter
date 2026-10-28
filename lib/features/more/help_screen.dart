import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_widgets.dart';

/// Help (PRD F-11): WhatsApp commands, example phrases and the reaction legend.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final commands = [
      ('/today', s.tr('Aaj ka plan', "Today's plan")),
      ('/tomorrow', s.tr('Kal ka plan', "Tomorrow's plan")),
      ('/calendar', s.tr('Agle 7 din', 'Next 7 days')),
      ('/free', s.tr('Aaj ka khali waqt', 'Free time today')),
      ('/list', s.tr('Aap ki lists (/list <naam>)', 'Your lists (/list <name>)')),
      ('/tasks', s.tr('Due kaam', 'Tasks with due dates')),
      ('/connect', s.tr('Google Calendar jorein', 'Link Google Calendar')),
      ('/undo', s.tr('Aakhri kaam wapas (15 min)', 'Undo the last action (15 min)')),
    ];
    final examples = [
      '"kal 2 bajay Ali se milna hai"',
      '"kal wali meeting 4 bajay kar do"',
      '"doodh, anday aur chai lena hai"',
      '"ek list banao office ke kaam ke liye"',
      '"doodh le liya"',
      '"kal kab free hoon?"',
    ];
    final reactions = [
      ('👀', s.tr('Kaam ho raha hai', 'Working on it')),
      ('✅', s.tr('Save ho gaya', 'Saved')),
      ('📅', s.tr('Command ka jawab', 'Command result')),
      ('⚠️', s.tr('Clash', 'Clash')),
      ('❓', s.tr('Aap ka jawab chahiye', 'Needs your input')),
      ('🛒', s.tr('List update', 'List updated')),
      ('↩️', s.tr('Wapas kar diya', 'Undone')),
      ('❌', s.tr('Samajh nahi aaya', 'Not understood')),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(title: s.tr('Help', 'Help'), kicker: 'Commands', onBack: () => context.canPop() ? context.pop() : context.go(Routes.more), backLabel: s.back),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(s.tr('WhatsApp commands', 'WhatsApp commands')),
                  HardBox(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (final (cmd, what) in commands)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 110, child: Text(cmd, style: YaadlyText.display(size: 15))),
                                Expanded(child: Text(what, style: YaadlyText.body(size: 14, color: YaadlyColors.clay))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  SectionLabel(s.tr('Bol kar ya likh kar', 'Say or type')),
                  for (final e in examples)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HardBox(
                        shadow: 2,
                        color: YaadlyColors.butter,
                        radius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                        padding: const EdgeInsets.all(12),
                        child: Text(e, style: YaadlyText.body(size: 14).copyWith(fontStyle: FontStyle.italic)),
                      ),
                    ),
                  const Gap(24),
                  SectionLabel(s.tr('Reactions ka matlab', 'What reactions mean')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final (e, what) in reactions) YChip('$e  $what', tone: YChipTone.sand)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
