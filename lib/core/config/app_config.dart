/// Build-time configuration, injected with `--dart-define` (see codemagic.yaml).
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://yaadley-api.mshiraz.com');

  /// WhatsApp number of the bot, digits only (used for wa.me deep links in M5).
  static const botWhatsAppNumber = String.fromEnvironment('BOT_WHATSAPP_NUMBER');
}
