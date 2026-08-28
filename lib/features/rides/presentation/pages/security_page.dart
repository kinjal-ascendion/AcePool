import 'package:acepool/core/constants/app_constants.dart';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security',
          style: GoogleFonts.mulish(
            color: const Color(0xFF1E1E1E),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
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
          color: const Color(0xFFFCE9E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC82323).withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFC82323), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Emergency SOS',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC82323),
                      height: 20 / 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Calls the support team and shares location',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      color: const Color(0xFFC82323),
                      fontWeight: FontWeight.w400,
                      height: 16 / 14,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E1E),
                      height: 18 / 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 18 / 14,
                    ),
                  ),
                  if (subtitle2 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle2,
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 18 / 14,
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
