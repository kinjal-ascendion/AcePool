import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_payment_bloc.dart';
import 'package:acepool/features/rides/presentation/pages/payment_success_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentPage extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final String rideId;

  const PaymentPage({
    super.key,
    required this.rideData,
    required this.rideId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RidePaymentBloc>(),
      child: _PaymentView(rideData: rideData, rideId: rideId),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.rideData, required this.rideId});

  final Map<String, dynamic> rideData;
  final String rideId;

  static const borderColor = Color(0xFFE0E0E0);
  static const innerBgColor = Color(0xFFF7F8F9);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RidePaymentBloc, RidePaymentState>(
      listener: (context, state) {
        if (state.status == RidePaymentStatus.success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                fromAddress: rideData['fromAddress'] ?? '',
                toAddress: rideData['toAddress'] ?? '',
              ),
            ),
            result: true,
          );
        }
      },
      builder: (context, state) {
        return _buildScaffold(context, state);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, RidePaymentState state) {
    final dateValue = rideData['date'];
    final DateTime rideDate;
    if (dateValue is Timestamp) {
      rideDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      rideDate = dateValue;
    } else {
      rideDate = DateTime.now();
    }

    final timeMap = rideData['time'] as Map<String, dynamic>?;
    final time = TimeOfDay(
      hour: timeMap?['hour'] as int? ?? 0,
      minute: timeMap?['minute'] as int? ?? 0,
    );

    final fareMap = rideData['fare'] as Map<String, dynamic>?;
    final totalFare = (fareMap?['farePerSeat'] as num? ?? 0.0).toDouble();
    final shortId = rideId.length >= 5
        ? rideId.substring(0, 5).toUpperCase()
        : rideId.toUpperCase();

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
          'Payment',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RIDE INFO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF757474),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                fontSize: 13,
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
                              _buildDetailRow('Person', '1'),
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
                              const Expanded(
                                child: Text(
                                  'Total fare to be paid',
                                  style: TextStyle(
                                    color: Color(0xFF757474),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '₹ ${totalFare.toStringAsFixed(2)}',
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
                  // Payment Methods Card
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
                          'Pay by any method listed below',
                          style: TextStyle(
                            color: Color(0xFF1D1D1D),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose how to pay for the ride',
                          style: TextStyle(
                            color: Color(0xFF757474),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // UPI Section
                        _buildUpiSection(context, state),
                        const SizedBox(height: 16),
                        // Cash Section
                        _buildCashOption(context, state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Done Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => context
                        .read<RidePaymentBloc>()
                        .add(RidePaymentCompleteRequested(rideId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: state.isSubmitting
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiSection(BuildContext context, RidePaymentState state) {
    final isSelected = state.selectedMethod == 'upi';
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B8A3F) : borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => context
                .read<RidePaymentBloc>()
                .add(const RidePaymentMethodSelected('upi')),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: const Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1B8A3F)),
            ),
            title: const Text(
              'UPI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: const Text(
              'Instant transfer',
              style: TextStyle(fontSize: 12, color: Color(0xFF757474)),
            ),
            trailing: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF1B8A3F) : borderColor,
            ),
          ),
          if (isSelected) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubPaymentButton('Google Pay', 'assets/images/gpay.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSubPaymentButton('Phone Pay', 'assets/images/phonepe.png'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF757474), style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text(
                        'Other payment methods',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubPaymentButton(String label, String assetPath) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for icon
          Container(
            width: 20,
            height: 20,
            color: Colors.grey[200],
            child: const Icon(Icons.payment, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashOption(BuildContext context, RidePaymentState state) {
    final isSelected = state.selectedMethod == 'cash';
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B8A3F) : borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => context
            .read<RidePaymentBloc>()
            .add(const RidePaymentMethodSelected('cash')),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF757474)),
        ),
        title: const Text(
          'Cash',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: const Text(
          'Pay after trip',
          style: TextStyle(fontSize: 12, color: Color(0xFF757474)),
        ),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? const Color(0xFF1B8A3F) : borderColor,
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
            width: 80,
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
                fontSize: 14,
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
