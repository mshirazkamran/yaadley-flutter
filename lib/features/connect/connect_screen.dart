import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/providers.dart';
import '../../core/data/yaadly_api.dart';
import '../../core/l10n/strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_icon.dart';
import '../../core/widgets/yaadly_widgets.dart';

/// Opens Google's consent page in a Custom Tab for this user. Shared by onboarding and Settings.
Future<void> openGoogleConnect(BuildContext context, WidgetRef ref) async {
  final s = ref.read(stringsProvider);
  try {
    final url = await ref.read(apiProvider).googleLinkUrl();
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    if (!ok && context.mounted) showSnack(context, s.tr('Browser nahi khul saka.', "Couldn't open the browser."));
  } catch (e) {
    if (context.mounted) showError(context, s, e);
  }
}

/// A3 Connect calendar (PRD F-3). Optional: "Baad mein" goes straight to Today.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> with WidgetsBindingObserver {
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the Custom Tab: re-read the profile to see whether Google is now connected.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) {
      ref.invalidate(meProvider);
      setState(() => _waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(meProvider);
    final google = me.value?.google;
    final connected = google?.connected ?? false;
    final perks = [
      s.tr('Events khud calendar mein add hon', 'Events go straight into your calendar'),
      s.tr('Clash pehle se check ho', 'Clashes are checked first'),
      s.tr('Kabhi bina poochay delete nahi', 'Nothing is deleted without asking'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(title: s.tr('Calendar connect karein', 'Connect your calendar'), kicker: 'Step 2 of 2'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, p) in perks.indexed)
                    Padding(
                      padding: EdgeInsets.only(left: i == 1 ? 24 : 0, right: i == 1 ? 0 : 24, bottom: 12),
                      child: HardBox(
                        shadow: 2,
                        color: i == 1 ? YaadlyColors.sand : YaadlyColors.butter,
                        radius: i == 1
                            ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
                            : const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4)),
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [const YaadlyIcon(YaadlyIcons.cal, size: 22), const Gap(12), Expanded(child: Text(p, style: YaadlyText.body(weight: FontWeight.w500)))]),
                      ),
                    ),
                  if (connected) ...[
                    const Gap(12),
                    HardBox(
                      color: YaadlyColors.sun,
                      radius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: YaadlyColors.ink, shape: BoxShape.circle),
                            child: const Center(child: YaadlyIcon(YaadlyIcons.check, color: YaadlyColors.butter)),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Google Calendar connected', style: YaadlyText.display(size: 16)),
                                if (google?.email != null) Text(google!.email!, style: YaadlyText.body(size: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (google != null && !google.available) ...[
                    const Gap(12),
                    Text(s.tr('Google Calendar abhi server par set nahi. Baad mein connect kar sakte hain.', "Google Calendar isn't set up on the server yet. You can connect later."),
                        style: YaadlyText.body(size: 14, color: YaadlyColors.clay)),
                  ],
                  const Gap(36),
                  if (connected)
                    YButton(label: s.tr('Today dekhein', 'Go to Today'), expand: true, onPressed: () => context.go(Routes.today))
                  else ...[
                    YButton(
                      label: _waiting ? 'Connecting…' : 'Connect Google Calendar',
                      expand: true,
                      onPressed: _waiting || google == null || !google.available
                          ? null
                          : () async {
                              setState(() => _waiting = true);
                              await openGoogleConnect(context, ref);
                            },
                    ),
                    const Gap(8),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(Routes.today),
                        child: Text(s.tr('Baad mein', 'Later'), style: YaadlyText.body(size: 14, weight: FontWeight.w600, color: YaadlyColors.clay).copyWith(decoration: TextDecoration.underline)),
                      ),
                    ),
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
