import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/features/rides/presentation/pages/security_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RideHistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> rideData;

  const RideHistoryDetailPage({super.key, required this.rideData});

  @override
  Widget build(BuildContext context) {
    final timestamp = rideData['date'] as Timestamp;
    final rideDate = timestamp.toDate();
    final timeMap = rideData['time'] as Map<String, dynamic>?;
    final time = TimeOfDay(
      hour: timeMap?['hour'] as int? ?? 0,
      minute: timeMap?['minute'] as int? ?? 0,
    );

    final isDriver = rideData['rideMode'] == 'offer';
    final fareMap = rideData['fare'] as Map<String, dynamic>?;
    final totalFare = isDriver 
        ? (fareMap?['driverEarnings'] ?? fareMap?['totalCost'] ?? 0.0)
        : (fareMap?['farePerSeat'] ?? 0.0);
    
    final personCount = isDriver 
        ? (rideData['seatsFilled'] ?? 0)
        : 1;

    final shortId = rideData['id'].toString().substring(0, 5).toUpperCase();

    // Figma light grey background for inner sections
    const innerBgColor = Color(0xFFF7F8F9);
    const borderColor = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x0A308666),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Color(0xFF308666),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ride Details',
                        style: TextStyle(
                          color: Color(0xFF1D1D1D),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Ride ID #$shortId',
                        style: const TextStyle(
                          color: Color(0xFF757474),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: innerBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('From', rideData['fromAddress'] ?? ''),
                        const Divider(height: 1, color: borderColor),
                        _buildDetailRow('To', rideData['toAddress'] ?? ''),
                        const Divider(height: 1, color: borderColor),
                        _buildDetailRow('Date & Time', DateTimeFormatter.monthDayYear(rideDate)),
                        const Divider(height: 1, color: borderColor),
                        _buildDetailRow('Time', DateTimeFormatter.time12h(time)),
                        const Divider(height: 1, color: borderColor),
                        _buildDetailRow('Person', personCount.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Ride Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Summary',
                    style: TextStyle(
                      color: Color(0xFF1D1D1D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: innerBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fare',
                          style: TextStyle(
                            color: Color(0xFF757474),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '₹ $totalFare',
                          style: const TextStyle(
                            color: Color(0xFF0F1923),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Help Section
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecurityPage()),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCFE8F1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need Help?',
                            style: TextStyle(
                              color: Color(0xFF1D1D1D),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'We are a tap away',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.black, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF757474),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F1923),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
