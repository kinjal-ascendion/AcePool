import 'package:acepool/core/constants/app_constants.dart';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildEmergencySosCard(context),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      icon: Icons.people_outline,
                      title: 'Contact Support 24/7',
                      subtitle: AppConstants.supportPhoneNumberMasked,
                      onTap: () => LocationShareHelper.launchDialer(
                        AppConstants.supportPhoneNumber,
                      ),
                    ),
                    Divider(color: AppColors.grey200, height: 1, indent: 56),
                    _buildRow(
                      icon: Icons.location_on_outlined,
                      title: 'Report an incident',
                      subtitle: 'support@ascendion.com',
                      subtitle2: 'Response within 24 hours',
                      onTap: () => LocationShareHelper.launchEmail(
                        to: 'support@ascendion.com',
                        subject: 'Incident Report',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencySosCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        LocationShareHelper.launchDialer(AppConstants.supportPhoneNumber);
        LocationShareHelper.shareCurrentLocation(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Calls the support team and shares location',
                style: TextStyle(fontSize: 13, color: AppColors.red.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? subtitle2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.grey700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: AppColors.grey600),
                  ),
                  if (subtitle2 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle2,
                      style: TextStyle(fontSize: 13, color: AppColors.grey600),
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
