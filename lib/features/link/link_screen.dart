import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/session.dart';
import '../../core/config/app_config.dart';
import '../../core/data/yaadly_api.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_icon.dart';
import '../../core/widgets/yaadly_widgets.dart';

/// A2 Link WhatsApp (PRD F-2). The app shows a code; the user sends it to the bot from their own
/// WhatsApp, which proves the number is theirs. We poll until the backend hands out tokens.
class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({super.key});

  @override
  ConsumerState<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends ConsumerState<LinkScreen> with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 2);

  PairingStart? _pairing;
  Object? _error;
  Timer? _tick;
  Timer? _poll;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  // Coming back from WhatsApp: check right away instead of waiting for the next poll.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus();
  }

  Duration get _left => _pairing == null ? Duration.zero : _pairing!.expiresAt.difference(DateTime.now());
  bool get _expired => _pairing != null && _left <= Duration.zero;

  Future<void> _start() async {
    _tick?.cancel();
    _poll?.cancel();
    setState(() {
      _pairing = null;
      _error = null;
    });
    try {
      final p = await ref.read(apiProvider).startPairing('Android');
      if (!mounted) return;
      setState(() => _pairing = p);
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_expired) _poll?.cancel();
      });
      _poll = Timer.periodic(_pollEvery, (_) => _checkStatus());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _checkStatus() async {
    final p = _pairing;
    if (p == null || _polling || _expired) return;
    _polling = true;
    try {
      final (status, tokens) = await ref.read(apiProvider).pairingStatus(p.pollToken);
      if (!mounted) return;
      if (tokens != null) {
        _poll?.cancel();
        _tick?.cancel();
        // The router moves on to "Connect calendar" once the session is signed in.
        await ref.read(sessionProvider.notifier).signedIn(tokens);
      } else if (status == 'expired') {
        _poll?.cancel();
        setState(() {});
      }
    } catch (_) {
      // Transient (offline): the next tick retries.
    } finally {
      _polling = false;
    }
  }

  Future<void> _openWhatsApp() async {
    final p = _pairing!;
    final url = p.whatsappUrl ??
        (AppConfig.botWhatsAppNumber.isEmpty ? null : 'https://wa.me/${AppConfig.botWhatsAppNumber}?text=${Uri.encodeComponent(p.message)}');
    final s = ref.read(stringsProvider);
    if (url == null || !await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: p.code));
      if (mounted) showSnack(context, s.tr('Code copy ho gaya. WhatsApp mein Yaadly ko bhej dein.', 'Code copied. Send it to Yaadly on WhatsApp.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final p = _pairing;
    final left = _left;
    final mm = left.inMinutes.clamp(0, 99).toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).clamp(0, 59).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(
              title: s.tr('WhatsApp link karein', 'Link WhatsApp'),
              kicker: s.tr('Step 1 of 2', 'Step 1 of 2'),
              onBack: () => context.go(Routes.welcome),
              backLabel: s.back,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HardBox(
                    color: _expired ? YaadlyColors.sand : YaadlyColors.butter,
                    radius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28), bottomRight: Radius.circular(28), bottomLeft: Radius.circular(6)),
                    padding: const EdgeInsets.all(20),
                    child: _error != null
                        ? Text(s.tr('Code nahi bana. Internet check karein.', "Couldn't get a code. Check your connection."), style: YaadlyText.display(size: 18))
                        : p == null
                            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: YaadlyColors.ink)))
                            : Column(
                                children: [
                                  Semantics(
                                    label: 'Code ${p.code}',
                                    excludeSemantics: true,
                                    child: Row(
                                      children: [
                                        for (var i = 0; i < p.code.length; i++) ...[
                                          if (i > 0) const Gap(8),
                                          Expanded(child: _Digit(p.code[i], offset: i.isOdd, struck: _expired)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Gap(20),
                                  Row(
                                    children: [
                                      _expired
                                          ? YChip(s.tr('Code expire ho gaya', 'Code expired'), tone: YChipTone.rust)
                                          : YChip(s.tr('Intezar…', 'Waiting…'), tone: YChipTone.ink),
                                      const Spacer(),
                                      Text('$mm:$ss', style: YaadlyText.display(size: 20).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                    ],
                                  ),
                                ],
                              ),
                  ),
                  const Gap(32),
                  for (final (i, step) in [
                    s.tr('WhatsApp kholein.', 'Open WhatsApp.'),
                    s.tr('Yaadly ko ye code bhejein.', 'Send this code to Yaadly.'),
                    s.tr('Wapas yahan aayein.', 'Come back here.'),
                  ].indexed)
                    Padding(
                      padding: EdgeInsets.only(left: i * 14.0, bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: YaadlyColors.ink, shape: BoxShape.circle),
                            child: Text('${i + 1}', style: YaadlyText.display(size: 14, color: YaadlyColors.butter)),
                          ),
                          const Gap(16),
                          Expanded(child: Text(step, style: YaadlyText.body(weight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  const Gap(24),
                  YButton(label: s.tr('WhatsApp kholein', 'Open WhatsApp'), expand: true, onPressed: p == null || _expired ? null : _openWhatsApp),
                  const Gap(12),
                  YButton(label: s.tr('Naya code', 'New code'), variant: YButtonVariant.paper, expand: true, onPressed: _start),
                  const Gap(16),
                  if (p != null && !_expired)
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: p.code));
                          if (context.mounted) showSnack(context, s.tr('Code copy ho gaya', 'Code copied'));
                        },
                        icon: const YaadlyIcon(YaadlyIcons.copy, size: 16, color: YaadlyColors.clay),
                        label: Text(s.tr('Code copy karein', 'Copy code'), style: YaadlyText.body(size: 14, weight: FontWeight.w600, color: YaadlyColors.clay)),
                      ),
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

class _Digit extends StatelessWidget {
  const _Digit(this.digit, {required this.offset, required this.struck});

  final String digit;
  final bool offset;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offset ? 6 : 0),
      child: HardBox.small(
        radius: BorderRadius.circular(12),
        child: SizedBox(
          height: 64,
          child: Center(
            child: Text(
              digit,
              style: YaadlyText.display(size: 30, color: struck ? YaadlyColors.tan : YaadlyColors.ink)
                  .copyWith(decoration: struck ? TextDecoration.lineThrough : null),
            ),
          ),
        ),
      ),
    );
  }
}
