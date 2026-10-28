import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/yaadly_colors.dart';
import 'core/theme/yaadly_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: YaadlyColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: YaadlyApp()));
}

class YaadlyApp extends ConsumerWidget {
  const YaadlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Yaadly',
      debugShowCheckedModeBanner: false,
      theme: buildYaadlyTheme(),
      routerConfig: ref.watch(routerProvider),
      // Roman Urdu is left-to-right Latin text, so Material stays on English (see strings.dart).
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
