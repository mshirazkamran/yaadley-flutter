import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/yaadly_icon.dart';

/// Bottom tab bar from the design: paper bar with an ink top border; the active tab gets a sun pill.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    // Loads the profile (and its language) and keeps the Inbox polling for the badge.
    ref.watch(meProvider);
    final unread = ref.watch(inboxProvider.select((v) => v.value?.unread ?? 0));
    final tabs = [
      (YaadlyIcons.today, s.tabToday),
      (YaadlyIcons.inbox, s.tabInbox),
      (YaadlyIcons.cal, s.tabCalendar),
      (YaadlyIcons.list, s.tabLists),
      (YaadlyIcons.more, s.tabMore),
    ];

    return Scaffold(
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: YaadlyColors.paper,
          border: Border(top: BorderSide(color: YaadlyColors.ink, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      icon: tabs[i].$1,
                      label: tabs[i].$2,
                      badge: i == 1 ? unread : 0,
                      selected: shell.currentIndex == i,
                      // Re-tapping the active tab returns that branch to its root.
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.icon, required this.label, required this.selected, required this.onTap, this.badge = 0});

  final YaadlyIcons icon;
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YaadlyColors.ink : YaadlyColors.clay;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge' : label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? YaadlyColors.sun : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? YaadlyColors.ink : Colors.transparent, width: 2),
              ),
              child: Badge(
                isLabelVisible: badge > 0,
                backgroundColor: YaadlyColors.rust,
                label: Text(badge > 9 ? '9+' : '$badge'),
                child: YaadlyIcon(icon, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: YaadlyText.display(size: 11, weight: FontWeight.w600, color: color).copyWith(height: 1.1)),
          ],
        ),
      ),
    );
  }
}
