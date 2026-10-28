import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../l10n/strings.dart';
import '../network/api_client.dart';
import '../theme/yaadly_colors.dart';
import '../theme/yaadly_theme.dart';
import 'hard_box.dart';
import 'yaadly_widgets.dart';

/// `Segmented` from the design: sand pill track, the selected option is an ink pill.
class YSegmented<T> extends StatelessWidget {
  const YSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return HardBox.small(
      color: YaadlyColors.sand,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in options)
            Semantics(
              selected: v == value,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: v == value ? YaadlyColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                  child: Text(label, style: YaadlyText.display(size: 14, weight: FontWeight.w600, color: v == value ? YaadlyColors.butter : YaadlyColors.clay)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `Toggle` from the design.
class YToggle extends StatelessWidget {
  const YToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 50,
          height: 30,
          child: HardBox.small(
            color: value ? YaadlyColors.sun : YaadlyColors.sand,
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: YaadlyColors.ink, shape: BoxShape.circle, border: Border.all(color: YaadlyColors.ink)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text input with the design's hard outline.
class YField extends StatelessWidget {
  const YField({super.key, required this.controller, this.hint, this.autofocus = false, this.onSubmitted, this.maxLength, this.keyboardType, this.pill = false});

  final TextEditingController controller;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    return HardBox.small(
      radius: BorderRadius.circular(pill ? 999 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: onSubmitted,
        style: YaadlyText.body(size: 16, weight: FontWeight.w500),
        cursorColor: YaadlyColors.ink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: YaadlyText.body(size: 16, color: YaadlyColors.clay),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Loading / error / data for an [AsyncValue], with pull-to-retry on errors.
class AsyncBody<T> extends ConsumerWidget {
  const AsyncBody({super.key, required this.value, required this.data, required this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    // Keep showing the previous data while refreshing (polling, pull to refresh).
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) {
      final e = value.error;
      final offline = e is ApiException && e.isNetwork;
      return Padding(
        padding: const EdgeInsets.all(YaadlySpace.page),
        child: HardBox(
          color: YaadlyColors.butter,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offline ? s.tr('Internet nahi mil raha', 'No connection') : s.tr('Kuch ghalat ho gaya', 'Something went wrong'), style: YaadlyText.display(size: 20)),
              const Gap(4),
              Text(s.tr('Dobara koshish karein.', 'Please try again.'), style: YaadlyText.body(color: YaadlyColors.clay)),
              const Gap(16),
              YButton(label: s.tr('Dobara try karein', 'Try again'), onPressed: onRetry),
            ],
          ),
        ),
      );
    }
    return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: YaadlyColors.ink, strokeWidth: 3)));
  }
}

/// Floating message, optionally with an action such as "Undo".
void showSnack(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: Duration(seconds: actionLabel == null ? 3 : 6),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, textColor: YaadlyColors.sun, onPressed: onAction ?? () {}),
    ),
  );
}

/// Shows an [ApiException] (or anything else) as a short, friendly snack.
void showError(BuildContext context, AppStrings s, Object error) {
  final e = error is ApiException ? error : null;
  final text = switch (e?.code) {
    'offline' || 'timeout' => s.tr('Internet nahi mil raha.', 'No connection.'),
    'list_exists' => s.tr('Is naam ki list pehle se hai.', 'A list with this name already exists.'),
    'not_found' => s.tr('Ye cheez ab mojood nahi.', 'This no longer exists.'),
    'not_answerable' => s.tr('Samajh nahi aaya ya sawal purana ho gaya.', 'Not understood, or the question expired.'),
    _ => s.tr('Kuch ghalat ho gaya, dobara try karein.', 'Something went wrong, try again.'),
  };
  showSnack(context, text);
}

/// Bottom sheet in the design's look (cream, ink top border, rounded top).
Future<T?> showYSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: YaadlyColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: YaadlyColors.ink, width: 2),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(YaadlySpace.page, 20, YaadlySpace.page, 24), child: builder(ctx)),
    ),
  );
}

/// Yes/no dialog for destructive actions.
Future<bool> confirmDialog(BuildContext context, {required String title, required String yes, required String no}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: HardBox(
        color: YaadlyColors.cream,
        radius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24), bottomLeft: Radius.circular(4)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: YaadlyText.display(size: 20).copyWith(height: 1.25)),
            const Gap(20),
            Row(
              children: [
                Expanded(child: YButton(label: yes, variant: YButtonVariant.ink, onPressed: () => Navigator.pop(ctx, true))),
                const Gap(10),
                Expanded(child: YButton(label: no, variant: YButtonVariant.paper, onPressed: () => Navigator.pop(ctx, false))),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return r ?? false;
}

/// Section label (`.label-caps`) with bottom spacing.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text.toUpperCase(), style: YaadlyText.labelCaps()));
}

/// Square checkbox from the design (ink when done).
class YCheck extends StatelessWidget {
  const YCheck({super.key, required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: done ? YaadlyColors.ink : YaadlyColors.butter,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: YaadlyColors.ink, width: 2),
      ),
      child: done ? const Icon(Icons.check_rounded, size: 16, color: YaadlyColors.butter) : null,
    );
  }
}
