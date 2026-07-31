class AppConstants {
  AppConstants._();

  static const String appName = 'AcePool';
  static const Duration splashDuration = Duration(seconds: 3);

  /// Placeholder 24/7 emergency support line. Swap for the real number
  /// before release.
  static const String supportPhoneNumber = '+914444444444';

  /// Masked version of [supportPhoneNumber] shown in the UI. Keep in sync
  /// with the real number above whenever it changes.
  static const String supportPhoneNumberMasked = '+91 44xxxxxxxx';
}
