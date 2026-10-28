import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/data/providers.dart';
import '../../core/data/yaadly_api.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_widgets.dart';
import '../calendar/event_sheet.dart';
import '../connect/connect_screen.dart';

/// More / Settings (PRD F-12): reply mode, auto-save, testing mode, reminders, language,
/// Google connection, WhatsApp link, server status, help and sign out.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> with WidgetsBindingObserver {
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

  // Back from the Google consent tab: show the new connection state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(meProvider);
  }

  Future<void> _update(Map<String, Object> patch) async {
    try {
      await ref.read(apiProvider).updateSettings(patch);
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) showError(context, ref.read(stringsProvider), e);
    }
  }

  Future<void> _signOut() async {
    final s = ref.read(stringsProvider);
    final ok = await confirmDialog(context, title: s.tr('Is phone se sign out karein?', 'Sign out on this phone?'), yes: s.tr('Haan', 'Yes'), no: s.tr('Nahi', 'No'));
    if (!ok) return;
    try {
      await ref.read(apiProvider).logout();
    } catch (_) {
      // Offline: still sign out locally; the server session expires on its own.
    }
    await ref.read(sessionProvider.notifier).signedOut();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(meProvider);
    final health = ref.watch(serverHealthProvider);
    final language = ref.watch(languageProvider);

    return RefreshIndicator(
      color: YaadlyColors.ink,
      onRefresh: () {
        ref.invalidate(serverHealthProvider);
        return ref.refresh(meProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ScreenHeader(title: s.tr('Settings', 'Settings'), kicker: s.tr('Aap ka Yaadly', 'Your Yaadly')),
          AsyncBody<Me>(
            value: me,
            onRetry: () => ref.invalidate(meProvider),
            data: (m) {
              final st = m.settings;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel(s.tr('Reply ka tareeqa', 'Reply preference')),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: YSegmented<DeliveryMode>(
                        options: [(DeliveryMode.chat, s.tr('Chat replies', 'Chat replies')), (DeliveryMode.app, s.tr('Sirf app', 'App only'))],
                        value: st.deliveryMode,
                        onChanged: (v) => _update({'deliveryMode': v.name}),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      st.deliveryMode == DeliveryMode.app
                          ? s.tr('WhatsApp par sirf reactions; tafseel app ke Inbox mein.', 'Only reactions on WhatsApp; details in the app Inbox.')
                          : s.tr('Bot WhatsApp par reply karega.', 'The bot replies on WhatsApp.'),
                      style: YaadlyText.body(size: 13, color: YaadlyColors.clay),
                    ),
                    const Gap(20),
                    _Group(children: [
                      _Row(label: s.tr('Events khud save hon', 'Auto-save events'), trailing: YToggle(value: st.autoSave, label: 'Auto-save', onChanged: (v) => _update({'autoSave': v}))),
                      _Row(
                        label: s.tr('Testing mode', 'Testing mode'),
                        detail: s.tr('App-only mein bhi chat reply', 'Chat replies even in app-only'),
                        trailing: YToggle(value: st.testingMode, label: 'Testing mode', onChanged: (v) => _update({'testingMode': v})),
                      ),
                      _Row(
                        label: s.tr('Zabaan', 'Language'),
                        trailing: YSegmented<AppLanguage>(
                          options: const [(AppLanguage.romanUrdu, 'RU'), (AppLanguage.english, 'EN')],
                          value: language,
                          onChanged: (v) {
                            ref.read(languageProvider.notifier).set(v);
                            _update({'language': v == AppLanguage.english ? 'en' : 'roman_ur'});
                          },
                        ),
                      ),
                      _Row(label: s.tr('Reminder', 'Reminder'), detail: s.tr('Event se pehle', 'Before each event'), trailing: _ReminderPicker(value: st.reminderMinutes, onChanged: (v) => _update({'reminderMinutes': v}))),
                    ]),
                    const Gap(20),
                    SectionLabel(s.tr('Connections', 'Connections')),
                    _Group(children: [
                      _Row(label: 'WhatsApp', detail: m.maskedNumber, trailing: YChip(s.tr('Linked', 'Linked'), tone: YChipTone.sun)),
                      _Row(
                        label: 'Google Calendar',
                        detail: m.google.connected
                            ? m.google.email
                            : m.google.revoked
                                ? s.tr('Link toot gaya, dobara jorein', 'Disconnected, reconnect')
                                : s.tr('Connect nahi', 'Not connected'),
                        trailing: !m.google.available
                            ? YChip(s.tr('Server par off', 'Off on server'), tone: YChipTone.sand)
                            : m.google.connected
                                ? _SmallButton(
                                    label: s.tr('Hatao', 'Disconnect'),
                                    onTap: () async {
                                      final ok = await confirmDialog(context,
                                          title: s.tr('Google Calendar disconnect karein? Purane events Google mein rehenge.', 'Disconnect Google Calendar? Existing events stay in Google.'),
                                          yes: s.tr('Haan', 'Yes'),
                                          no: s.tr('Nahi', 'No'));
                                      if (!ok) return;
                                      try {
                                        await ref.read(apiProvider).disconnectGoogle();
                                        ref.invalidate(meProvider);
                                      } catch (e) {
                                        if (context.mounted) showError(context, s, e);
                                      }
                                    },
                                  )
                                : _SmallButton(label: s.tr('Jorein', 'Connect'), onTap: () => openGoogleConnect(context, ref)),
                      ),
                      _Row(
                        label: s.serverStatus,
                        detail: Uri.parse(AppConfig.apiBaseUrl).host,
                        trailing: switch (health) {
                          AsyncData(value: true) => YChip(s.serverOnline, tone: YChipTone.sun),
                          AsyncData() || AsyncError() => YChip(s.serverOffline, tone: YChipTone.rust),
                          _ => YChip(s.serverChecking, tone: YChipTone.sand),
                        },
                      ),
                    ]),
                    const Gap(24),
                    YButton(label: s.tr('Commands aur help', 'Commands & help'), variant: YButtonVariant.paper, expand: true, onPressed: () => context.push(Routes.help)),
                    const Gap(10),
                    YButton(label: s.tr('Sign out', 'Sign out'), variant: YButtonVariant.ink, expand: true, onPressed: _signOut),
                    const Gap(16),
                    Center(
                      child: TextButton(
                        onPressed: () => launchUrl(Uri.parse('${AppConfig.apiBaseUrl}/privacy'), mode: LaunchMode.inAppBrowserView),
                        child: Text(s.tr('Privacy policy', 'Privacy policy'), style: YaadlyText.body(size: 13, color: YaadlyColors.clay).copyWith(decoration: TextDecoration.underline)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HardBox(
      radius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26), bottomLeft: Radius.circular(26), bottomRight: Radius.circular(6)),
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 2, thickness: 2, color: YaadlyColors.ink.withValues(alpha: 0.1)),
            c,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing, this.detail});

  final String label;
  final String? detail;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: YaadlyText.body(weight: FontWeight.w600)),
                if (detail != null) Text(detail!, style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
              ],
            ),
          ),
          const Gap(12),
          trailing,
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoicePill(label: label, selected: false, onTap: onTap, color: YaadlyColors.sun);
}

class _ReminderPicker extends ConsumerWidget {
  const _ReminderPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [0, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    String label(int m) => m == 0 ? s.tr('Off', 'Off') : '$m min';
    return PopupMenuButton<int>(
      initialValue: value,
      onSelected: onChanged,
      color: YaadlyColors.paper,
      itemBuilder: (_) => [for (final m in _options) PopupMenuItem(value: m, child: Text(label(m), style: YaadlyText.body()))],
      child: HardBox.small(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(label(value), style: YaadlyText.display(size: 14, weight: FontWeight.w600)),
      ),
    );
  }
}
