import 'package:acepool/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationShareHelper {
  LocationShareHelper._();

  static Future<void> shareCurrentLocation(
    BuildContext context, {
    String message = 'Emergency! My current location: ',
  }) async {
    final position = await LocationService().getCurrentLocation();
    if (!context.mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location')),
      );
      return;
    }
    final link =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    await Share.share('$message$link');
  }

  static Future<void> launchDialer(String phoneNumber) {
    return launchUrl(Uri(scheme: 'tel', path: phoneNumber));
  }

  static Future<void> launchEmail({required String to, String? subject}) {
    return launchUrl(
      Uri(
        scheme: 'mailto',
        path: to,
        query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
      ),
    );
  }
}
